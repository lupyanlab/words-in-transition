from __future__ import print_function

from invoke import task
import yaml
from unipath import Path
from fabric.api import env
from fabric.operations import run, sudo, put
import pandas as pd

from .qualtrics import Qualtrics

seeds_dir = 'seeds'
env.host_string = 'pierce@sapir.psych.wisc.edu'
host_dst = '/var/www/stimuli/words-in-transition/'
url_dst = 'http://sapir.psych.wisc.edu/stimuli/words-in-transition/seeds/'

seed_info_csv = 'seed_info.csv'

@task
def create_seed_info():
    """Create a csv of info about the seeds on the server."""
    seeds = Path(seeds_dir).listdir('*.wav', names_only=True)
    seed_info = pd.DataFrame({'filename': seeds})
    seed_info['url'] = url_dst + seed_info.filename
    seed_info.to_csv(seed_info_csv, index=False)

@task(create_seed_info)
def put_seeds_on_server():
    """Copy the seed files to the server."""
    # sudo('mkdir ' + host_dst)
    put(seeds_dir, host_dst, use_sudo=True)

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
