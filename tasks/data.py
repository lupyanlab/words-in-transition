#!/usr/bin/env python
from shutil import copytree

from invoke import task, run
import pandas as pd
from unipath import Path
import enchant

from .tidy import *
from .match_transcriptions import (match_to_transcription_pilot_data,
                                   make_match_transcriptions)

r_pkg_root = Path('wordsintransition')
src_dir = Path(r_pkg_root, 'data-raw/src')
csv_output_dir = Path(r_pkg_root, 'data-raw')

d = enchant.Dict('en_US')


@task
def get():
    """Get the data from the telephone-app project."""
    app_dir = Path('../telephone-app')
    snapshot_dir = Path(app_dir, 'words-in-transition')
    if src_dir.exists():
        src_dir.rmtree()
    copytree(snapshot_dir, src_dir)


@task
def csv():
    """Create tidy csvs from the raw data dumps."""
    imitations = make_imitations(Path(src_dir, 'grunt.Message.json'))
    imitations.to_csv(Path(csv_output_dir, 'imitations.csv'), index=False)

    subjects = make_subjects(Path(src_dir, 'mturk_survey_results.csv'))
    subjects.to_csv(Path(csv_output_dir, 'subjects.csv'), index=False)

    # match imitations
    surveys = make_surveys(Path(src_dir, 'ratings.Survey.json'))
    questions = make_questions(Path(src_dir, 'ratings.Question.json'), imitations)
    questions = questions.merge(surveys)

    match_imitations = make_match_imitations(Path(src_dir, 'ratings.Response.json'))
    match_imitations = match_imitations.merge(questions)
    match_imitations = match_imitations.merge(subjects, how='left')
    match_imitations = match_imitations.merge(imitations)

    match_imitations['is_correct'] =\
        (match_imitations.selection == match_imitations.answer).astype(int)

    match_imitations.to_csv(
        Path(csv_output_dir, 'match_imitations.csv'),
        index=False,
    )

    # transcriptions
    transcription_surveys = make_transcription_surveys(Path(src_dir, 'transcribe.TranscriptionSurvey.json'))
    transcription_questions = make_transcription_questions(Path(src_dir, 'transcribe.MessageToTranscribe.json'))
    transcriptions = make_transcriptions(Path(src_dir, 'transcribe.Transcription.json'))
    # Apparently some people used ASCII characters
    transcriptions['text'] = transcriptions.text.str.encode('utf-8').str.strip()

    transcriptions = transcriptions.merge(transcription_questions)
    transcriptions = transcriptions.merge(transcription_surveys)
    transcriptions = transcriptions.merge(imitations[['imitation_id', 'seed_id', 'chain_name']])

    transcriptions = transcriptions.ix[transcriptions.transcription_survey_name.isin(['hand picked 1', 'hand picked 1 seeds'])]
    transcriptions['is_catch_trial'] = transcriptions.chain_name.str.endswith('.wav').astype(int)
    transcriptions.to_csv(Path(csv_output_dir, 'transcriptions.csv'), index=False)

    transcription_frequencies = transcriptions.ix[transcriptions.is_catch_trial == 0]
    transcription_frequencies['text'] = transcription_frequencies.text.str.lower()
    groupers = ['chain_name', 'seed_id', 'imitation_id']
    transcription_frequencies = (transcription_frequencies.groupby(groupers)
                              .text
                              .value_counts()
                              .reset_index()
                              .rename(columns={0: 'n'}))
    transcription_frequencies['is_english'] = transcription_frequencies.text.apply(check_english).astype(int)
    transcription_frequencies.to_csv(Path(csv_output_dir, 'transcription_frequencies.csv'),
                       index=False)

    # match transcriptions
    match_to_transcriptions_1 = match_to_transcription_pilot_data()
    match_to_transcriptions_1['experiment'] = 'pilot'
    match_to_transcriptions_2 = make_match_transcriptions(Path(src_dir))
    match_to_transcriptions_2 = match_to_transcriptions_2.merge(subjects, how='left')
    match_to_transcriptions_2['experiment'] = 'test'
    match_to_transcriptions = pd.concat(
        [match_to_transcriptions_1, match_to_transcriptions_2],
    )
    match_to_transcriptions.to_csv(
        Path(csv_output_dir, 'match_transcriptions.csv'),
        index=False,
    )


def identify_responses(django_app_name):
    """Join survey and question info to table of responses.

    TODO: Rename transcribe models to be Survey, Question, and Response.

    Args:
        django_app_name (str): The prefix for the models to look for,
            e.g., 'words', 'ratings'
    """
    surveys = format_survey('words.Survey.json')
    questions = format_questions('words.Question.json')
    responses = format_questions('')


@task
def rdata():
    """Run the use_data script in the wordsintransition R package."""
    cmd = "cd {} && Rscript data-raw/use-data.R"
    run(cmd.format(r_pkg_root))


@task
def install():
    """Install the wordsintransition R package."""
    # watch quotes!
    r_commands = [
        'devtools::document("wordsintransition")',
        'devtools::install("wordsintransition")',
    ]
    for r_command in r_commands:
        run("Rscript -e '{}'".format(r_command))


def check_english(text):
    return all([d.check(w) for w in text.split(' ')])
