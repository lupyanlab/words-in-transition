from invoke import task, run
from unipath import Path
import pandas as pd


@task
def get_transcriptions():
    run('cp wordsintransition/data-raw/transcriptions.csv match-transcriptions/')
