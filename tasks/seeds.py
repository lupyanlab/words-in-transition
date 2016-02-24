from __future__ import print_function

from invoke import task, run as local_run
import yaml
from unipath import Path
from fabric.api import env
from fabric.operations import sudo, put
import pandas as pd

from .qualtrics import Qualtrics

seeds_dir = 'norm-seeds/all-seeds'
host_dst = '/var/www/stimuli/words-in-transition/'
url_dst = 'http://sapir.psych.wisc.edu/stimuli/words-in-transition/all-seeds/'

seed_info_csv = 'norm-seeds/all-seeds.csv'

@task
def convert_wav_to_mp3(src_dir=None):
    """Convert wav sounds to mp3."""
    if src_dir is None:
        src_dir = seeds_dir
    wav_seeds = Path(src_dir).listdir('*.wav', names_only=True)
    for wav in wav_seeds:
        mp3 = Path(wav).stem + '.mp3'
        cmd = 'ffmpeg -i {} -codec:a libmp3lame -qscale:a 2 {}'
        local_run(cmd.format(Path(src_dir, wav), Path(src_dir, mp3)))

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
def create_loop_merge():
    """Create a loop and merge spreadsheet."""
    outfile = 'norm-seeds/survey-1/loop_merge.csv'
    seed_info = pd.read_csv(seed_info_csv)
    loop_merge = seed_info.pivot('category', 'id', 'url')
    loop_merge.reset_index(inplace=True)
    loop_merge['loop_merge_row'] = range(1, len(loop_merge)+1)
    loop_merge.to_csv(outfile, index=False)

@task
def download_qualtrics_file_info():
    """Download info including urls from Qualtrics library."""
    creds = get_creds()
    qualtrics = Qualtrics(**creds)
    response = qualtrics.get(Request='getQualtricsIdsForLibrary', Format='JSON', LibraryID='UR_3yiQbNZVD204sE5')
    print(response.json())

@task
def download_survey(name):
    """Download a survey from Qualtrics."""
    creds = get_creds()
    qualtrics = Qualtrics(**creds)
    survey = qualtrics.get_survey(name)
    print(survey)

def get_creds():
    qualtrics_api_creds = 'qualtrics_api_creds.yml'
    return yaml.load(open(qualtrics_api_creds))
