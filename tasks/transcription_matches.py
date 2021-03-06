from invoke import task, run
from unipath import Path
import pandas as pd

from .qualtrics import Qualtrics
from .seeds import convert_wav_to_mp3, get_creds
from .tidy import unfold_model_fields

experiment_dir = Path('experiments/5-transcription-matches/')
surveys_dir = Path(experiment_dir, 'surveys')
qualtrics_dir = Path(surveys_dir, 'qualtrics')

# catch trial word for app surveys
APP_CATCH_TRIAL_WORDS = [
    "Attention check: Pick the third option.",
    "Attention check: Pick the third option",
]


OUTPUT_COLUMNS = [
    'version', 'subj_id',
    'seed_id', 'message_id', 'word', 'word_category',
    'question_type', 'choice_id', 'choice_category',
    'is_correct',
]


def make_transcription_matches(app_data_dir, app_subjs):
    pilot = make_transcription_matches_pilot()
    app = make_transcription_matches_app(app_data_dir, app_subjs)
    matches = pd.concat([pilot, app])
    return matches

def make_transcription_matches_pilot():
    """Process match imitation surveys from the pilot experiment on Qualtrics.

    This function processes the raw Qualtrics output, labels the Qualtrics
    columns using the loop and merge csvs, and puts the result in tidy
    format.

    This function assumes the Qualtrics output has already been downloaded
    and that the location of the loop and merge csvs is also hard-coded in.
    """
    all_surveys = []
    for survey_name in ['match_to_seed_1', 'match_to_seed_2']:
        survey = pd.read_csv(
            Path(qualtrics_dir, 'responses/{}.csv'.format(survey_name)),
            skiprows=[0,],
        )

        loop_merge = pd.read_csv(
            Path(qualtrics_dir, 'loop_merge/{}.csv'.format(survey_name)),
        )

        choice_cols = ['choice_1', 'choice_2', 'choice_3', 'choice_4']
        choices = loop_merge[choice_cols].drop_duplicates()
        loop_merge.drop(choice_cols, axis=1, inplace=True)

        choice_map = pd.melt(choices, var_name='choice_label', value_name='url')
        choice_map['choice'] = choice_map.choice_label.str.extract('(\d)', expand=True).astype(int)
        choice_map['choice_filename'] =\
            choice_map.url.apply(lambda x: Path(x).stem)
        choice_map['choice_id'] = (
            choice_map.choice_filename
                      .str.extract('(\d+)$', expand=False)
                      .astype(int))
        choice_map = choice_map.ix[:, ['choice', 'choice_filename', 'choice_id']]

        id_col = 'workerId'

        survey = pd.melt(survey, id_col, var_name='qualtrics_col',
                         value_name='choice')
        re_seed = r'^([a-z]+\-\d+)\ \((\d)\)$'
        survey[['filename', 'row']] =\
            survey.qualtrics_col.str.extract(re_seed, expand=True)

        survey.dropna(inplace=True)
        survey['row'] = survey.row.astype(int)
        survey['survey_name'] = survey_name
        survey = survey.merge(loop_merge)
        survey = survey.merge(choice_map)

        # Label the question type
        survey_info = pd.read_csv(Path(qualtrics_dir, 'source_info.csv'))
        survey_info['question_type'] = 'exact'
        survey_info.loc[:, 'question_type'] =\
            survey_info.question_type.where(
                survey_info.survey_name == survey_name,
                'category'
            )
        survey_info.loc[:, 'filename'] = survey_info.filename.apply(lambda x: Path(x).stem)
        survey_info = survey_info[['filename', 'question_type']]
        survey = survey.merge(survey_info)

        all_surveys.append(survey)

    final = pd.concat(all_surveys)
    final.sort_values(id_col, inplace=True)

    final['seed_id'] = final.filename.str.split('-').str.get(1).astype(int)
    final['choice_category'] = final.choice_filename.str.split('-').str.get(0)

    final.rename(
        columns=dict(workerId='subj_id',
                     text='word',
                     chain_name='word_category'),
        inplace=True,
    )

    message_id_labels = pd.read_csv(
        Path(qualtrics_dir, 'transcriptions/selected-edited.csv')
    )[['text', 'seed_id', 'message_id']].rename(columns=dict(text='word'))
    final = final.merge(message_id_labels, how='left')

    final['version'] = 'pilot'
    final['is_correct'] = (final.word_category ==
                           final.choice_category).astype(int)
    final.rename(columns={'message_id': 'message_id'}, inplace=True)

    return final[OUTPUT_COLUMNS]


def make_transcription_matches_app(src_dir, subjs):
    """Make match transcriptions data from DB dumps.

    cf. match.make_transcription_matches_pilot
    """
    surveys = pd.read_json(Path(src_dir, 'words.Survey.json'))
    del surveys['model']
    unfold_model_fields(surveys, ['name', 'catch_trial_id'])
    surveys.rename(
        columns=dict(pk='survey_id', name='survey_name'),
        inplace=True,
    )

    # label survey version
    survey_labels = {}
    survey_versions = dict(
        version_a = ['match imitations seeds %s' % n for n in [1, 2]],
        version_b = ['version-b-seeds-%s' % n for n in [1, 2, 3, 4]],
        version_c = ['version-c-seeds-%s' % n for n in [1, 2, 3, 4]],
    )
    for label, survey_names in survey_versions.items():
        for survey_name in survey_names:
            survey_labels[survey_name] = label
    surveys['version'] = surveys.survey_name.map(survey_labels)

    questions = pd.read_json(Path(src_dir, 'words.Question.json'))
    del questions['model']
    unfold_model_fields(questions, ['word', 'survey', 'choices'])
    questions.rename(
        columns=dict(pk='question_id', survey='survey_id'),
        inplace=True,
    )
    questions = questions.merge(surveys)

    # Label word category, message id, seed id for questions
    # NOTE: Some transcriptions were given to multiple messages
    version_a = format_answer_key('version_a', APP_CATCH_TRIAL_WORDS[0])
    version_b = format_answer_key('version_b', APP_CATCH_TRIAL_WORDS[1])
    version_c = format_answer_key('version_c', APP_CATCH_TRIAL_WORDS[1])
    answer_key = pd.concat([version_a, version_b, version_c],
                           ignore_index=True)
    questions = questions.merge(answer_key)

    # Label question type and correct answer for each question
    questions['question_type'] = questions.apply(label_question_type, axis=1)
    labels = format_choice_category_labels(answer_key)
    questions =\
        questions.groupby('question_type').apply(label_answer_id, labels=labels)

    responses = pd.read_json(Path(src_dir, 'words.Response.json'))
    del responses['model']
    unfold_model_fields(responses, ['selection', 'question'])
    responses.rename(
        columns=dict(pk='response_id',
                     question='question_id',
                     selection='choice_id'),
        inplace=True,
    )

    # Label choice category
    responses = responses.merge(labels)

    # Combine responses with questions
    matches = responses.merge(questions)
    matches['is_correct'] = (matches.choice_id == matches.answer_id).astype(int)

    # label subj id
    subjects = subjs.ix[subjs.experiment == 'transcription_matches']
    matches = matches.merge(subjects, how='left')

    return matches[OUTPUT_COLUMNS]


def format_answer_key(version_label, catch_trial_text):
    """Format the eligble transcriptions to be merged with the questions."""
    selected_csv = Path(surveys_dir, version_label,
                        'selected_transcriptions.csv')
    selected = pd.read_csv(selected_csv)
    selected['version'] = version_label
    selected = selected[
        ['version', 'chain_name', 'seed_id', 'message_id', 'text']
    ].rename(columns={'chain_name': 'word_category', 'text': 'word'})

    catch_trial = dict(word_category='catch_trial', word=catch_trial_text,
                       version = version_label, seed_id=-1, message_id=-1)
    selected = selected.append(catch_trial, ignore_index=True)
    return selected


def format_choice_category_labels(answer_key):
    labels = answer_key.ix[answer_key.word_category != 'catch_trial']
    labels = labels.ix[:, ['word_category', 'seed_id']].drop_duplicates()
    labels.rename(
        columns=dict(word_category='choice_category',
                     seed_id='choice_id'),
        inplace=True,
    )
    return labels


def label_question_type(question):
    if question.seed_id in question.choices:
        question_type = 'exact'
    elif question.word in APP_CATCH_TRIAL_WORDS:
        question_type = 'catch_trial'
    else:
        question_type = 'category'
    return question_type


def label_answer_id(chunk, labels):
    question_type = chunk.iloc[0, :]["question_type"]

    if question_type == "catch_trial":
        # The correct choice on catch trials is the third option
        chunk['answer_id'] = chunk.choices.apply(lambda x: x[2])
    elif question_type == "exact":
        # The choice is the actual seed
        chunk['answer_id'] = chunk.seed_id
    else:
        # The correct choice is the other message in the seeds
        chunk['answer_id'] =\
            chunk.apply(label_category_answer, axis=1, labels=labels)

    return chunk


def label_category_answer(category_question, labels):
    category_ix = (labels.choice_category == category_question.word_category)
    not_exact_match = (labels.choice_id != category_question.seed_id)
    in_choices = labels.choice_id.isin(category_question.choices)
    category_ids = labels.ix[category_ix & not_exact_match & in_choices,
                             "choice_id"]
    assert len(category_ids) == 1
    return category_ids.squeeze()
