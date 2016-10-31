"""Determine which seeds to use to start the Telephone chains."""
from __future__ import print_function
import os
from invoke import task, run as local_run
import yaml
from unipath import Path
# from fabric.api import env
# from fabric.operations import sudo, put
import pandas as pd

from .qualtrics import Qualtrics

project_root = Path('.').absolute()
tasks_dir = Path(project_root, 'tasks')

exp_dir = Path(project_root, 'experiments/1-determine-seeds')
seeds_dir = Path(exp_dir, 'all-seeds')
seed_info_csv = Path(exp_dir, 'all-seeds.csv')

report_dir = Path(project_root, 'reports/1-determine-seeds')

host_dst = '/var/www/stimuli/words-in-transition/'
url_dst = 'http://sapir.psych.wisc.edu/stimuli/words-in-transition/all-seeds/'

out_dir = Path(project_root, 'wordsintransition/data-raw')

@task
def convert_wav_to_mp3(src_dir=None, dst_dir=None):
    """Convert wav sounds to mp3."""
    if src_dir is None:
        src_dir = seeds_dir
    if dst_dir is None:
        dst_dir = src_dir

    src_dir = Path(src_dir)
    assert src_dir.exists()

    dst_dir = Path(dst_dir)
    if not dst_dir.exists():
        dst_dir.mkdir(True)

    wav_seeds = Path(src_dir).listdir('*.wav', names_only=True)
    for wav in wav_seeds:
        mp3 = Path(wav).stem + '.mp3'
        cmd = 'ffmpeg -i {} -codec:a libmp3lame -qscale:a 2 {}'
        local_run(cmd.format(Path(src_dir, wav), Path(dst_dir, mp3)))

@task
def create_seed_info():
    """Create a csv of info about the seeds on the server."""
    re_filename = '([a-z]+)_\d+\.mp3'
    seeds = Path(seeds_dir).listdir('*.mp3', names_only=True)
    seed_info = pd.DataFrame({'filename': seeds})
    seed_info['category'] = seed_info.filename.str.extract(re_filename)
    seed_info['id'] = seed_info.groupby('category').cumcount() + 1
    seed_info['url'] = url_dst + seed_info.filename
    seed_info.to_csv(seed_info_csv, index=False)

@task
def put_seeds_on_server(src_dir=None):
    """Copy the seed files to the server."""
    env.host_string = 'pierce@sapir.psych.wisc.edu'
    if src_dir is None:
        src_dir = seeds_dir
    put(src_dir, host_dst, use_sudo=True)

@task
def create_loop_merge(survey_name):
    """Create a loop and merge spreadsheet."""
    seed_info = pd.read_csv(seed_info_csv)
    outfile = Path(exp_dir, survey_name, 'loop_merge.csv')

    if survey_name == 'sound_similarity_4':
        # get odd sounds from previous survey
        odd_sounds_csv = Path(report_dir, 'odd_sounds.csv')
        odd_sounds = pd.read_csv(odd_sounds_csv)
        seeds_to_keep = ~seed_info.filename.isin(odd_sounds.filename)
        seed_info = seed_info.ix[seeds_to_keep].reset_index(drop=True)
        # reset id value to be 1:4
        seed_info['id'] = seed_info.groupby('category').cumcount() + 1

        # save the selection to file
        selected_csv = Path(report_dir, 'selected_seeds.csv')
        seed_info.to_csv(selected_csv, index=False)

    loop_merge = seed_info.pivot('category', 'id', 'url')
    loop_merge.reset_index(inplace=True)
    loop_merge['loop_merge_row'] = range(1, len(loop_merge)+1)
    loop_merge.to_csv(outfile, index=False)


@task(help={'survey_name': 'sound_similarity_6 or sound_similarity_4'})
def download_survey_responses(survey_name):
    """Download the survey data.

    Args:
        survey_name: 'sound_similarity_6' or 'sound_similarity_4'
    """
    qualtrics = Qualtrics(**get_creds())
    responses = qualtrics.get_survey_responses(survey_name)
    survey_dir = Path(exp_dir, survey_name)
    if not survey_dir.exists():
        survey_dir.mkdir()

    output = Path(survey_dir, survey_name + '.csv')
    responses.to_csv(output, index=False)

@task
def tidy_surveys(survey_name=None):
    """Parse the data in tidy format."""
    # tidy all surveys by default
    survey_names = [survey_name] if survey_name else \
                   ['sound_similarity_6', 'sound_similarity_6']
    for survey_name in survey_names:
        _tidy_survey(survey_name)

def _tidy_survey(survey_name):
    # Inputs
    survey_csv = Path(exp_dir, survey_name, survey_name + '.csv')
    survey = pd.read_csv(survey_csv, skiprows=[0, ])

    loop_merge_csv = Path(exp_dir, survey_name, 'loop_merge.csv')
    loop_merge = pd.read_csv(loop_merge_csv)

    # Outputs
    survey_dir = Path(out_dir, survey_name)
    if not survey_dir.exists():
        survey_dir.mkdir()

    bad_subjs_csv = Path(survey_dir, 'bad_subjs.csv')
    odd_one_out_csv = Path(survey_dir, 'odd_one_out.csv')

    # Begin tidying
    id_col = 'workerId'

    # label the workers who passed the catch trial
    survey.loc[:, 'describe_catch'].fillna('', inplace=True)
    survey['failed_catch_trial'] = ~survey.describe_catch.str.contains(
        'piano', case=False
    )

    # export the subjects to deny payment
    survey.ix[survey.failed_catch_trial].to_csv(bad_subjs_csv, index=False)

    # label the workers who reported problems with audio
    is_problem_col = survey.columns.str.contains('problems\ ')
    problem_cols = survey.columns[is_problem_col].tolist()
    problem = pd.melt(survey, id_col, problem_cols,
                      var_name = 'qualtrics', value_name = 'problem_with_audio')

    problem['loop_merge_row'] = problem.qualtrics.str.extract('\((\d)\)$').astype(int)
    problem['problem_with_audio'] = problem.problem_with_audio.fillna(False).astype(bool)
    problem.drop('qualtrics', axis=1, inplace=True)

    # combine filters
    subjs = pd.merge(survey[[id_col, 'failed_catch_trial']], problem)
    subjs['failed_catch_trial'] = subjs.failed_catch_trial.astype(int)
    subjs['problem_with_audio'] = subjs.problem_with_audio.astype(int)

    # tidy the survey data
    is_odd_col = survey.columns.str.contains('odd_one_out\ ')
    odd_cols = survey.columns[is_odd_col].tolist()
    odd = pd.melt(survey, id_col, odd_cols,
                  var_name = 'qualtrics', value_name = 'odd_one_out')

    odd['loop_merge_row'] = odd.qualtrics.str.extract('\((\d)\)$').astype(int)

    file_map = pd.melt(loop_merge.drop('loop_merge_row', axis=1),
                       'category', var_name='odd_one_out', value_name='url')
    file_map['odd_one_out'] = file_map.odd_one_out.astype(int)
    file_map['filename'] = file_map.url.apply(lambda x: Path(x).name)
    file_map.drop('url', axis=1, inplace=True)

    odd = odd.merge(loop_merge[['category', 'loop_merge_row']])
    odd = odd.merge(file_map)
    odd = odd.merge(subjs)
    odd.sort(['workerId', 'category'], inplace=True)

    odd = odd[['workerId', 'failed_catch_trial', 'problem_with_audio', 'category', 'filename']]
    odd.to_csv(odd_one_out_csv, index=False)


def get_creds():
    qualtrics_api_creds = Path(tasks_dir, 'qualtrics_api_creds.yml')
    return yaml.load(open(qualtrics_api_creds))

@task
def determine_odd_sounds():
    local_run('Rscript reports/1-determine-seeds/odd_sounds.R')

@task
def select_final_seeds():
    local_run('Rscript reports/1-determine-seeds/final_seeds.R')
    final_seeds_csv = Path(report_dir, 'final_seeds.csv')
    final_seeds = pd.read_csv(final_seeds_csv)
    final_dir = Path(exp_dir, 'final-seeds')
    if not os.path.isdir(final_dir):
        os.mkdir(final_dir)
    for seed in final_seeds.filename.tolist():
        src = Path(seeds_dir, seed)
        dst = Path(final_dir, seed)
        mv = 'cp {src} {dst}'
        local_run(mv.format(src=src, dst=dst))
