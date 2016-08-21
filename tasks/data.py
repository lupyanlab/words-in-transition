#!/usr/bin/env python
from shutil import copytree

from invoke import task, run
import pandas as pd
from unipath import Path
import enchant

from .tidy import *
from .transcription_matches import make_transcription_matches

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

    subjects = make_subjects(Path(src_dir, 'mturk_subjects.csv'))
    subjects.to_csv(Path(csv_output_dir, 'subjects.csv'), index=False)

    # match imitations
    surveys = make_surveys(Path(src_dir, 'ratings.Survey.json'))
    questions = make_questions(Path(src_dir, 'ratings.Question.json'), imitations)
    questions = questions.merge(surveys)

    imitation_matches = make_imitation_matches(Path(src_dir, 'ratings.Response.json'))
    imitation_matches = imitation_matches.merge(questions)
    i_m_subjs = subjects.ix[subjects.experiment == "imitation_matches"]
    imitation_matches = imitation_matches.merge(i_m_subjs, how='left')
    imitation_matches = imitation_matches.merge(imitations)

    imitation_matches['is_correct'] =\
        (imitation_matches.selection == imitation_matches.answer).astype(int)

    imitation_matches.to_csv(
        Path(csv_output_dir, 'imitation_matches.csv'),
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
    transcription_frequencies.loc[:, 'text'] =\
        transcription_frequencies.text.str.lower()
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
    transcription_matches = make_transcription_matches(
        app_data_dir=Path(src_dir), app_subjs=subjects,
    )
    transcription_matches.to_csv(
        Path(csv_output_dir, 'transcription_matches.csv'),
        index=False,
    )


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
