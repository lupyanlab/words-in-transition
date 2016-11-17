#!/usr/bin/env python
from shutil import copytree

from invoke import task, run
import pandas as pd
from unipath import Path

from .tidy import *
from .transcription_matches import make_transcription_matches
from .transcription_frequencies import summarize_transcription_frequency
from .transcription_distances import summarize_transcription_distance

r_pkg_root = Path('wordsintransition')
data_raw = Path(r_pkg_root, 'data-raw')
src_dir = Path(data_raw, 'src')
csv_output_dir = Path(r_pkg_root, 'data-raw')


@task(help=dict(project="One of telephone-app, acoustic-similarity, learning-sound-names. If none is provided, all are assumed."))
def get(project=None):
    """Get the data from the telephone-app and acoustic-similarity projects."""
    if project is None or project == 'telephone-app':
        app_dir = Path('../telephone-app')
        snapshot_dir = Path(app_dir, 'words-in-transition')
        if src_dir.exists():
            src_dir.rmtree()
        copytree(snapshot_dir, src_dir)

    if project is None or project == 'acoustic-similarity':
        # src
        proj_dir = Path('../acoustic-similarity/data')
        judgments = Path(proj_dir, 'judgments')

        # dst
        acoustic_similarity_dir = Path(data_raw, 'acoustic-similarity')
        if not acoustic_similarity_dir.isdir():
            acoustic_similarity_dir.mkdir()

        # copy the csvs in the root proj data dir
        for csv in proj_dir.listdir('*.csv'):
            csv.copy(acoustic_similarity_dir)

        # concat and save judgments files
        judgments_csv = Path(acoustic_similarity_dir, 'judgments.csv')
        judgments = [pd.read_csv(x) for x in judgments.listdir('*.csv')]
        if judgments:
            (pd.concat(judgments, ignore_index=True)
               .to_csv(judgments_csv, index=False))

    if project is None or project == 'learning-sound-names':
        src = Path('../learning-sound-names/data')
        dst = Path(data_raw, 'learning_sound_names.csv')
        data = pd.concat([pd.read_csv(x) for x in src.listdir('*.csv')])
        data['is_correct'] = data.is_correct.astype(int)
        data.to_csv(dst, index=False)


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
    transcriptions = transcriptions.merge(imitations[['message_id', 'seed_id', 'chain_name']])

    transcription_survey_names = [
        'hand picked 1',
        'hand picked 1 seeds',
        'remaining-proximal-and-distal-1',
        'first-gen-partial-1',
    ]

    transcriptions = transcriptions.ix[
        transcriptions.transcription_survey_name.isin(
            transcription_survey_names
        )
    ]
    transcriptions['is_catch_trial'] = transcriptions.chain_name.str.endswith('.wav').astype(int)
    transcriptions.to_csv(Path(csv_output_dir, 'transcriptions.csv'), index=False)

    frequencies = summarize_transcription_frequency(transcriptions)
    frequencies.to_csv(Path(csv_output_dir, 'transcription_frequencies.csv'),
                       index=False)

    distances = summarize_transcription_distance(transcriptions)
    distances.to_csv(Path(csv_output_dir, 'transcription_distances.csv'),
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
