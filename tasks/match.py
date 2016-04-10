from invoke import task, run
from unipath import Path
import pandas as pd
import json

from .qualtrics import Qualtrics
from .seeds import convert_wav_to_mp3, get_creds
from .survey import pluck

match_transcriptions_dir = Path('match-transcriptions')
surveys_dir = Path(match_transcriptions_dir, 'surveys')


@task
def get():
    """Get all transcriptions from the R pkg.

    Since the transcriptions come from the DB, they are all copied,
    and then filtered for the particular surveys.
    """
    run('cp wordsintransition/data-raw/transcriptions.csv match-transcriptions/')


@task
def select():
    """Select the most frequent transcriptions to be matched.

    The selected transcriptions are put in survey-specific directories.
    After they are selected, they should be edited by hand to remove any
    bad ones.
    """
    run('Rscript describe_transcriptions.R')


@task
def create(survey_name):
    """Create surveys from the template.

    Two Qualtrics surveys are created: one with version 1 options,
    the other with version 2 options. The same transcriptions are
    tested in both surveys.
    """
    transcriptions = pd.read_csv(Path(surveys_dir, survey_name, 'transcriptions/selected-edited.csv'))
    create_survey(survey_name, transcriptions, version=1)
    create_survey(survey_name, transcriptions, version=2)


@task
def download():
    """Download Qualtrics responses."""
    qualtrics = Qualtrics(**get_creds())
    for survey_name in ['match_to_seed_1', 'match_to_seed_2']:
        responses = qualtrics.get_survey_responses(survey_name)
        responses.to_csv('match-transcriptions/qualtrics/{}.csv'.format(survey_name),
                         index=False)


@task
def tidy():
    """Compile all Qualtrics response data into a single csv."""
    all_surveys = []
    for survey_name in ['match_to_seed_1', 'match_to_seed_2']:
        survey_csv = Path(surveys_dir, 'match_to_seed/responses/{}.csv'.format(survey_name))
        survey = pd.read_csv(survey_csv, skiprows=[0,])

        loop_merge_csv = Path(surveys_dir, 'match_to_seed/loop_merge/{}.csv'.format(survey_name))
        loop_merge = pd.read_csv(loop_merge_csv)

        choice_cols = ['choice_1', 'choice_2', 'choice_3', 'choice_4']
        choices = loop_merge[choice_cols].drop_duplicates()
        loop_merge.drop(choice_cols, axis=1, inplace=True)

        choice_map = pd.melt(choices, var_name='choice_label', value_name='url')
        choice_map['choice'] = choice_map.choice_label.str.extract('(\d)', expand=True).astype(int)
        choice_map['choice_filename'] = choice_map.url.apply(lambda x: Path(x).stem)
        choice_map = choice_map[['choice', 'choice_filename']]

        id_col = 'workerId'

        survey = pd.melt(survey, id_col, var_name='qualtrics_col', value_name='choice')
        re_seed = r'^([a-z]+\-\d+)\ \((\d)\)$'
        survey[['filename', 'row']] = survey.qualtrics_col.str.extract(re_seed, expand=True)

        survey.dropna(inplace=True)
        survey['row'] = survey.row.astype(int)
        survey['survey_name'] = survey_name
        survey = survey.merge(loop_merge)
        survey = survey.merge(choice_map)

        # Label the question type
        survey_info = pd.read_csv('match-transcriptions/source_info.csv')
        survey_info['question_type'] = 'exact'
        survey_info['question_type'] = survey_info.question_type.where(survey_info.survey_name == survey_name, 'category')
        survey_info['filename'] = survey_info.filename.apply(lambda x: Path(x).stem)
        survey_info = survey_info[['filename', 'question_type']]
        survey = survey.merge(survey_info)

        all_surveys.append(survey)

    final = pd.concat(all_surveys)
    final.sort_values(id_col, inplace=True)

    final['seed_id'] = final.filename.str.split('-').str.get(1)
    final['choice_category'] = final.choice_filename.str.split('-').str.get(0)

    final.rename(columns=dict(workerId='subj_id', chain_name='text_category'), inplace=True)

    final = final[['subj_id', 'survey_name', 'seed_id', 'text', 'text_category', 'question_type', 'choice_filename', 'choice_category']]
    final['is_correct'] = (final.text_category == final.choice_category).astype(int)

    final.to_csv('match-transcriptions/matches.csv', index=False)


@task
def put():
    """Put the match to transcription data in the R pkg raw data dir."""
    run('cp match-transcriptions/matches.csv wordsintransition/data-raw/matches.csv')


def create_survey(survey_name, transcriptions, version):
    """Create a Qualtrics survey from the template."""
    template = json.load(open(Path(surveys_dir, 'template.qsf')))
    return json.dumps(template)


def convert():
    convert_wav_to_mp3(match_transcriptions_seeds_dir)


def put_seeds_on_server():
    from fabric.api import env
    from fabric.operations import put
    src_dir = match_transcriptions_seeds_dir
    host_dst = '/var/www/stimuli/words-in-transition'
    env.host_string = 'pierce@sapir.psych.wisc.edu'
    put(src_dir, host_dst, use_sudo=True)


def sound_info():
    """Create a csv of info about the seeds on the server."""
    url_dst = 'http://sapir.psych.wisc.edu/stimuli/words-in-transition/transcription-sources/'
    re_filename = r'^([a-z]+)-(\d+)\.mp3$'
    seeds = Path(match_transcriptions_seeds_dir).listdir('*.mp3', names_only=True)
    seed_info = pd.DataFrame({'filename': seeds})
    seed_info[['category', 'message_id']] = seed_info.filename.str.extract(re_filename, expand=True)
    seed_info['url'] = url_dst + seed_info.filename

    # Add survey name
    seed_info['survey_name'] = 'match_to_seed_' + (seed_info.groupby('category').cumcount() + 1).astype(str)

    seed_info.to_csv('match-transcriptions/source_info.csv', index=False)


def loop_merge(transcriptions_csv, version):
    versions = {'1': ['glass-34', 'tear-39', 'water-42', 'zipper-47'],
                '2': ['glass-35', 'tear-41', 'water-45', 'zipper-49']}
    assert version in versions,\
        "don't know seeds for version {}".format(version)

    transcriptions = pd.read_csv(transcriptions_csv)
    transcriptions = transcriptions[['chain_name', 'text']]

    source_info = pd.read_csv('match-transcriptions/source_info.csv')

    for i, choice in enumerate(versions[version]):
        field = 'choice_{}'.format(i)


def tidy_survey(survey_name, survey_version):
    survey_version_name = '{}_{}'.format(survey_name, survey_version)
    src = Path(surveys_dir, survey_name, 'responses', survey_version_name + '.csv')
    survey = pd.read_csv(src, skiprows=[0,])

    loop_merge = pd.read_csv(Path(surveys_dir, survey_name, 'loop_merge', survey_version_name + '.csv'))

    choice_cols = ['choice_1', 'choice_2', 'choice_3', 'choice_4']
    choices = loop_merge[choice_cols].drop_duplicates()
    loop_merge.drop(choice_cols, axis=1, inplace=True)

    choice_map = pd.melt(choices, var_name='choice_label', value_name='url')
    choice_map['choice'] = choice_map.choice_label.str.extract('(\d)', expand=True).astype(int)
    choice_map['choice_filename'] = choice_map.url.apply(lambda x: Path(x).stem)
    choice_map = choice_map[['choice', 'choice_filename']]

    id_col = 'workerId'

    survey = pd.melt(survey, id_col, var_name='qualtrics_col', value_name='choice')
    re_seed = r'^([a-z]+\-\d+)\ \((\d)\)$'
    survey[['filename', 'row']] = survey.qualtrics_col.str.extract(re_seed, expand=True)

    survey.dropna(inplace=True)
    survey['row'] = survey.row.astype(int)
    survey['survey_name'] = survey_version_name
    survey = survey.merge(loop_merge)
    survey = survey.merge(choice_map)

    # Label the question type
    survey_info = pd.read_csv('match-transcriptions/source_info.csv')
    survey_info['question_type'] = 'exact'
    survey_info['question_type'] = survey_info.question_type.where(survey_info.survey_name == survey_name, 'category')
    survey_info['filename'] = survey_info.filename.apply(lambda x: Path(x).stem)
    survey_info = survey_info[['filename', 'question_type']]
    survey = survey.merge(survey_info)

    survey.sort_values(id_col, inplace=True)

    survey['seed_id'] = survey.filename.str.split('-').str.get(1)
    survey['choice_category'] = survey.choice_filename.str.split('-').str.get(0)

    survey.rename(columns=dict(workerId='subj_id', chain_name='text_category'), inplace=True)

    survey = survey[['subj_id', 'survey_name', 'seed_id', 'text', 'text_category', 'question_type', 'choice_filename', 'choice_category']]
    survey['is_correct'] = (survey.text_category == survey.choice_category).astype(int)

    return survey
