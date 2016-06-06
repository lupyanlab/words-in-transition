from invoke import task, run
from unipath import Path
import pandas as pd

from .qualtrics import Qualtrics
from .seeds import convert_wav_to_mp3, get_creds
from .tidy import unfold_model_fields

report_dir = Path('reports/5-match-to-seed-transcriptions/')
qualtrics_dir = Path(report_dir, 'surveys/qualtrics')


def download_qualtrics():
    """Download match imitation data from Qualtrics."""
    qualtrics = Qualtrics(**get_creds())
    for survey_name in ['match_to_seed_1', 'match_to_seed_2']:
        responses = qualtrics.get_survey_responses(survey_name)
        responses.to_csv(
            Path(qualtrics_dir, 'responses/{}.csv'.format(survey_name)),
            index=False,
        )


def make_transcription_matches_pilot():
    """Process match imitation surveys from Qualtrics.

    This function processes the raw Qualtrics output, labels the Qualtrics
    columns using the loop and merge csvs, and puts the result in tidy
    format.

    This function assumes the Qualtrics output has already been downloaded
    and that the location of the loop and merge csvs is also hard-coded in.
    """
    all_surveys = []
    for survey_name in ['match_to_seed_1', 'match_to_seed_2']:
        survey = pd.read_csv(
            Path(qualtrics_dir, 'responses/{}.csv'.format(survey_name)),
            skiprows=[0,],
        )

        loop_merge = pd.read_csv(
            Path(qualtrics_dir, 'loop_merge/{}.csv'.format(survey_name)),
        )

        choice_cols = ['choice_1', 'choice_2', 'choice_3', 'choice_4']
        choices = loop_merge[choice_cols].drop_duplicates()
        loop_merge.drop(choice_cols, axis=1, inplace=True)

        choice_map = pd.melt(choices, var_name='choice_label', value_name='url')
        choice_map['choice'] = choice_map.choice_label.str.extract('(\d)', expand=True).astype(int)
        choice_map['choice_filename'] = choice_map.url.apply(lambda x: Path(x).stem)
        choice_map = choice_map[['choice', 'choice_filename']]

        id_col = 'workerId'

        survey = pd.melt(survey, id_col, var_name='qualtrics_col', value_name='choice')
        re_seed = r'^([a-z]+\-\d+)\ \((\d)\)$'
        survey[['filename', 'row']] = survey.qualtrics_col.str.extract(re_seed, expand=True)

        survey.dropna(inplace=True)
        survey['row'] = survey.row.astype(int)
        survey['survey_name'] = survey_name
        survey = survey.merge(loop_merge)
        survey = survey.merge(choice_map)

        # Label the question type
        survey_info = pd.read_csv(Path(qualtrics_dir, 'source_info.csv'))
        survey_info['question_type'] = 'exact'
        survey_info['question_type'] = survey_info.question_type.where(survey_info.survey_name == survey_name, 'category')
        survey_info['filename'] = survey_info.filename.apply(lambda x: Path(x).stem)
        survey_info = survey_info[['filename', 'question_type']]
        survey = survey.merge(survey_info)

        all_surveys.append(survey)

    final = pd.concat(all_surveys)
    final.sort_values(id_col, inplace=True)

    final['seed_id'] = final.filename.str.split('-').str.get(1)
    final['choice_category'] = final.choice_filename.str.split('-').str.get(0)

    final.rename(columns=dict(workerId='subj_id', chain_name='text_category'), inplace=True)

    final = final[['subj_id', 'survey_name', 'seed_id', 'text', 'text_category', 'question_type', 'choice_filename', 'choice_category']]
    final['is_correct'] = (final.text_category == final.choice_category).astype(int)

    return final


def make_transcription_matches_app(src_dir):
    """Make match transcriptions data from DB dumps.

    cf. match.make_transcription_matches_pilot
    """
    surveys = pd.read_json(Path(src_dir, 'words.Survey.json'))
    del surveys['model']
    unfold_model_fields(surveys, ['name', 'catch_trial_id'])
    surveys.rename(
        columns=dict(pk='survey_id', name='survey_name'),
        inplace=True,
    )

    questions = pd.read_json(Path(src_dir, 'words.Question.json'))
    del questions['model']
    unfold_model_fields(questions, ['word', 'survey', 'choices'])
    questions.rename(
        columns=dict(pk='question_id', survey='survey_id'),
        inplace=True,
    )

    # determine correct answer for each question!
    # questions['answer'] = ...

    # determine question type for each question
    # e.g., catch_trial, true_seed, category_match
    # questions['question_type'] = ...

    responses = pd.read_json(Path(src_dir, 'words.Response.json'))
    del responses['model']
    unfold_model_fields(responses, ['selection', 'question'])
    responses.rename(
        columns=dict(pk='response_id', question='question_id'),
        inplace=True,
    )

    transcription_matches = (responses.merge(questions)
                                     .merge(surveys))
    return transcription_matches
