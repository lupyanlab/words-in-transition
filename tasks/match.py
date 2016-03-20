from invoke import task, run
from unipath import Path
import pandas as pd


@task
def get_transcriptions():
    run('cp wordsintransition/data-raw/transcriptions.csv match-transcriptions/')

@task
def loop_merge():
    transcriptions = pd.read_csv('match-transcriptions/selected-edited.csv')
    reject_ixs = transcriptions.index[transcriptions.rejected == 1.0]
    transcriptions.drop(reject_ixs, inplace=True)
