from invoke import task, run
import pandas as pd
from unipath import Path


# data source: snapshot and mturk data from telephone-app directory
app_dir = Path('../telephone-app')
snapshot_dir = Path(app_dir, 'words-in-transition')

# destination: raw data dir inside R pkg
r_pkg_root = Path('wordsintransition')
csv_output_dir = Path(r_pkg_root, 'data-raw')


@task
def messages():
    """Process the message models."""
    message_model = 'grunt.Message.json'
    messages = pd.read_json(Path(snapshot_dir, message_model))

    del messages['model']

    message_model_fields = (
        'audio chain parent generation rejected verified start_at end_at'
    ).split()
    unfold_model_fields(messages, message_model_fields)

    extract_from_path(messages)

    messages.sort_values(['game_name', 'chain_name', 'message_name'],
                         inplace=True)

    rename_ids = dict(pk='message_id', chain='chain_id', parent='parent_id')
    messages.rename(columns=rename_ids, inplace=True)

    label_seed_messages(messages)

    messages.to_csv(Path(csv_output_dir, 'messages.csv'), index=False)


@task(messages)
def questions():
    """Process the question models."""
    question_model_dump = 'ratings.Question.json'
    questions = pd.read_json(Path(snapshot_dir, question_model_dump))

    del questions['model']

    question_model_fields = 'choices given survey answer'.split()
    unfold_model_fields(questions, question_model_fields)

    questions.rename(columns=dict(pk='question_id', survey='survey_id'),
                     inplace=True)

    messages = pd.read_csv(Path(csv_output_dir, 'messages.csv'))
    seed_map = messages[['message_id', 'seed_id', 'chain_name']]
    questions = questions.merge(seed_map, left_on='given', right_on='message_id')
    del questions['message_id']  # redundant with given

    def determine_answer(question):
        if question.seed_id in question.choices:
            seed_id = question.seed_id
        else:
            # get chain name of true seed
            seed_chain = seed_map.ix[seed_map.seed_id == question.seed_id, 'chain_name']
            # label choices by chain name
            choice_info = seed_map.ix[seed_map.seed_id.isin(question.choices)]
            # select choice from same chain name as seed
            seed_id = choice_info.ix[choice_info.chain_name == seed_chain, 'seed_id']
        question['answer'] = seed_id
        return question

    questions = questions.apply(determine_answer, axis=1)

    def determine_question_type(question):
        if question.given in question.choices:
            question_type = 'catch_trial'
        elif question.seed_id in question.choices:
            question_type = 'true_seed'
        else:
            question_type = 'category_match'
        question['question_type'] = question_type
        return question

    questions = questions.apply(determine_question_type, axis=1)

    questions.to_csv(Path(csv_output_dir, 'questions.csv'), index=False)


@task
def subjects():
    """Process the MTurk assignments so they can be merged with responses.

    TODO: Some people took the survey multiple times, so codes should be labeled
          with run number for each subject.
    """
    mturk = pd.read_csv(Path(snapshot_dir, 'mturk_survey_results.csv'))
    split = mturk.completionCode.str.split('-')
    def zip_codes(completion_code):
        try:
            return {k: v for k, v in enumerate(completion_code)}
        except TypeError:
            return {}
    codes = pd.DataFrame.from_records(split.apply(zip_codes))
    codes['subj_id'] = mturk.WorkerId
    labeled = pd.melt(codes, id_vars='subj_id', var_name='response_ix', value_name='response_id')

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
    labeled.sort_values(['subj_id', 'response_ix'], inplace=True)
    labeled.to_csv(Path(csv_output_dir, 'subjects.csv'), index=False)


@task(questions, subjects)
def responses():
    """Process the response models."""
    responses = pd.read_json(Path(snapshot_dir, 'ratings.Response.json'))
    unfold_model_fields(responses, ['selection', 'question'])
    responses.rename(columns=dict(pk='response_id', question='question_id'),
                     inplace=True)

    questions = pd.read_csv(Path(csv_output_dir, 'questions.csv'))
    responses = responses.merge(questions)

    subjects = pd.read_csv(Path(csv_output_dir, 'subjects.csv'))
    responses = responses.merge(subjects)

    responses.to_csv(Path(csv_output_dir, 'responses.csv'), index=False)




def unfold(objects, name):
    """Pull the named value out of a list of objects."""
    return objects.apply(lambda x: x[name])


def unfold_model_fields(json_frame, fields):
    for name in fields:
        json_frame[name] = unfold(json_frame.fields, name)
    del json_frame['fields']


def extract_from_path(frame):
    splits = frame.audio.str.split('/')
    path_args = ['game_name', 'chain_name', 'message_name']
    assert len(path_args) <= len(splits[0])
    for i, name in enumerate(path_args):
        frame[name] = splits.str.get(i)


def label_seed_messages(frame):

    def find_seed(message):
        if message.generation == 0:
            return message.message_id
        parent = frame.ix[frame.message_id == message.parent_id].squeeze()
        return find_seed(parent)

    frame['seed_id'] = frame.apply(find_seed, axis=1)
