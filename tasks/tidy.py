"""Convert json DB dumps from telephone app to csvs for analysis."""
import pandas as pd

from unipath import Path


def make_subjects(subjects_csv):
    """Process the MTurk assignments so they can be merged with responses.

    TODO: Some people took the survey multiple times, so codes should be labeled
          with run number for each subject.
    """
    mturk = pd.read_csv(subjects_csv)
    split = mturk.completionCode.str.split('-')
    def zip_codes(completion_code):
        try:
            return {k: v for k, v in enumerate(completion_code)}
        except TypeError:
            return {}
    codes = pd.DataFrame.from_records(split.apply(zip_codes))

    codes['subj_id'] = mturk.WorkerId
    codes['experiment'] = mturk.experiment

    labeled = pd.melt(codes, id_vars=['experiment', 'subj_id'],
                      var_name='response_ix', value_name='response_id')

    def coerce_int(x):
        # replace non-int response_ids with missing values
        try:
            int(x)
        except ValueError:
            return ''
        else:
            return x

    labeled['response_id'] = labeled.response_id.apply(coerce_int)
    labeled = labeled.ix[labeled.response_id != '']
    labeled['response_id'] = labeled.response_id.astype(int)
    labeled.sort_values(['experiment', 'subj_id', 'response_ix'], inplace=True)
    return labeled


def make_imitations(imitations_json):
    imitations = pd.read_json(imitations_json)
    del imitations['model']

    imitation_model_fields = ['audio', 'chain', 'parent', 'generation', 'rejected', 'verified', 'start_at', 'end_at']
    unfold_model_fields(imitations, imitation_model_fields)

    # extract game name and chain name from path to wav
    extract_from_path(imitations)

    imitations.sort_values(['game_name', 'chain_name', 'imitation_name'], inplace=True)
    imitations.rename(columns=dict(pk='message_id', chain='chain_id', parent='parent_id'), inplace=True)

    imitations['seed_id'] = imitations.apply(find_imitation_on_branch, generation=0, frame=imitations, axis=1)
    imitations['first_gen_id'] = imitations.apply(find_imitation_on_branch, generation=1, frame=imitations, axis=1)

    return imitations


def make_surveys(surveys_json):
    surveys = pd.read_json(surveys_json)
    del surveys['model']

    unfold_model_fields(surveys, ['name', 'num_questions_per_player'])
    surveys.rename(columns=dict(pk='survey_id', name='survey_name'),
                   inplace=True)

    surveys['survey_type'] = surveys.survey_name.str.split('-').str.get(0)

    surveys = surveys[surveys.survey_type != 'test']

    return surveys

def make_questions(questions_json, imitations):
    questions = pd.read_json(questions_json)
    del questions['model']

    question_model_fields = ['choices', 'given', 'survey', 'answer']
    unfold_model_fields(questions, question_model_fields)

    questions.rename(columns=dict(pk='question_pk', survey='survey_id', given='message_id'),
                     inplace=True)

    # question id is unique combination of choices and given imitation
    # question pk is unique for all question models in the db
    question_id_str = questions.choices.astype(str) + questions.message_id.astype(str)
    questions['question_id_str'] = question_id_str
    question_id_map = {qstr: qid for qid, qstr in enumerate(question_id_str.unique())}
    questions['question_id'] = questions.question_id_str.apply(lambda x: question_id_map[x])
    del questions['question_id_str']

    seed_map = imitations[['message_id', 'seed_id', 'chain_name']]
    questions = questions.merge(seed_map)

    chain_seeds = seed_map[['chain_name', 'seed_id']].drop_duplicates()

    def determine_answer(question):
        if question.seed_id in question.choices:
            seed_id = question.seed_id
        else:
            # get chain name of true seed
            seed_chain = chain_seeds.ix[chain_seeds.seed_id == question.seed_id, 'chain_name'].values[0]
            # label choices by chain name
            choice_info = chain_seeds.ix[chain_seeds.seed_id.isin(question.choices)]
            # select choice from same chain name as seed
            seed_id = choice_info.ix[choice_info.chain_name == seed_chain, 'seed_id'].values[0]
        question['answer'] = seed_id
        return question

    questions = questions.apply(determine_answer, axis=1)

    def determine_question_type(question):
        if question.message_id in question.choices:
            question_type = 'catch_trial'
        elif question.seed_id in question.choices:
            question_type = 'true_seed'
        else:
            question_type = 'category_match'
        question['question_type'] = question_type
        return question

    questions = questions.apply(determine_question_type, axis=1)

    return questions

def make_imitation_matches(responses_json):
    imitation_matches = pd.read_json(responses_json)
    del imitation_matches['model']

    unfold_model_fields(imitation_matches, ['selection', 'question'])
    imitation_matches.rename(
        columns=dict(pk='response_id', question='question_pk'),
        inplace=True,
    )

    return imitation_matches


def make_transcription_surveys(surveys_json):
    surveys = pd.read_json(surveys_json)
    del surveys['model']

    unfold_model_fields(surveys, ['name', 'catch_trial_id'])
    surveys.rename(
        columns=dict(pk='transcription_survey_id',
                     name='transcription_survey_name'),
        inplace=True,
    )

    return surveys

def make_transcription_questions(questions_json):
    questions = pd.read_json(questions_json)
    del questions['model']

    unfold_model_fields(questions, ['given', 'survey'])
    questions.rename(
        columns=dict(pk='imitation_to_transcribe_id', given='message_id',
                     survey='transcription_survey_id'),
        inplace=True,
    )

    return questions

def make_transcriptions(transcriptions_json):
    transcriptions = pd.read_json(transcriptions_json)
    del transcriptions['model']

    unfold_model_fields(transcriptions, ['message', 'text'])
    transcriptions.rename(
        columns=dict(pk='transcription_id',
                     message='imitation_to_transcribe_id'),
        inplace=True,
    )

    return transcriptions


def unfold(objects, name):
    """Pull the named value out of a list of objects."""
    return objects.apply(lambda x: x[name])


def unfold_model_fields(json_frame, fields):
    for name in fields:
        json_frame[name] = unfold(json_frame.fields, name)
    del json_frame['fields']


def extract_from_path(frame):
    splits = frame.audio.str.split('/')
    path_args = ['game_name', 'chain_name', 'imitation_name']
    assert len(path_args) <= len(splits[0])
    for i, name in enumerate(path_args):
        frame[name] = splits.str.get(i)

def find_imitation_on_branch(imitation, generation, frame):
    if imitation.generation == generation:
        return imitation.message_id
    elif imitation.generation < generation:
        # imitation will never be found
        return -1
    else:
        parent = frame.ix[frame.message_id == imitation.parent_id].squeeze()
        return find_imitation_on_branch(parent, generation, frame)

def label_seed_imitations(frame):
    frame['seed_id'] = frame.apply(find_imitation_on_branch, generation=0, frame=frame, axis=1)

    def find_seed(imitation):
        if imitation.generation == 0:
            return imitation.message_id
        parent = frame.ix[frame.message_id == imitation.parent_id].squeeze()
        return find_seed(parent)

    frame['seed_id'] = frame.apply(find_seed, axis=1)

def label_seed_imitations(frame):

    def find_seed(imitation):
        if imitation.generation == 0:
            return imitation.message_id
        parent = frame.ix[frame.message_id == imitation.parent_id].squeeze()
        return find_seed(parent)

    frame['seed_id'] = frame.apply(find_seed, axis=1)
