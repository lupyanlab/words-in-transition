from __future__ import print_function

from invoke import task
import yaml
from unipath import Path
from fabric.api import env
from fabric.operations import run, put

from .qualtrics import Qualtrics

env.host_string = 'pierce@sapir.psych.wisc.edu'

@task(help={'seeds_dir': 'Location of directory containing seeds'})
def put_seeds_on_server(seeds_dir='seeds'):
    """Copy the seed files to the server."""
    dst = '/var/www/stimuli/words-in-transition'
    run('mkdir ' + dst)
    put(seeds_dir, dst)

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
