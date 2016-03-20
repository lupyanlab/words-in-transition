from invoke import task, run
from unipath import Path
import pandas as pd

from .seeds import convert_wav_to_mp3

match_transcriptions_seeds_dir = 'match-transcriptions/transcription-sources/'

@task
def get_transcriptions():
    run('cp wordsintransition/data-raw/transcriptions.csv match-transcriptions/')

@task
def summarize():
    run('Rscript describe_transcriptions.R')

@task
def get_seed_wavs():
    raise NotImplementedError

@task
def convert():
    convert_wav_to_mp3(match_transcriptions_seeds_dir)

@task
def put_seeds_on_server():
    from fabric.api import env
    from fabric.operations import put
    src_dir = match_transcriptions_seeds_dir
    host_dst = '/var/www/stimuli/words-in-transition'
    env.host_string = 'pierce@sapir.psych.wisc.edu'
    put(src_dir, host_dst, use_sudo=True)

@task
def sound_info():
    """Create a csv of info about the seeds on the server."""
    url_dst = 'http://sapir.psych.wisc.edu/stimuli/words-in-transition/{}'.format(
        match_transcriptions_seeds_dir
    )
    re_filename = r'^([a-z]+)-(\d+)\.mp3$'
    seeds = Path(match_transcriptions_seeds_dir).listdir('*.mp3', names_only=True)
    seed_info = pd.DataFrame({'filename': seeds})
    seed_info[['category', 'message_id']] = seed_info.filename.str.extract(re_filename, expand=True)
    seed_info['url'] = url_dst + seed_info.filename

    seed_info.to_csv('match-transcriptions/source_info.csv', index=False)

@task
def survey_info():
    transcriptions = pd.read_csv('match-transcriptions/selected-edited.csv')
    reject_ixs = transcriptions.index[transcriptions.rejected == 1.0]
    transcriptions.drop(reject_ixs, inplace=True)
    transcriptions.to_csv('match-transcriptions/survey-1.csv')
