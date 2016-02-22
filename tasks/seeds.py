from __future__ import print_function

from invoke import task
import yaml
from unipath import Path

from .qualtrics import Qualtrics

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
