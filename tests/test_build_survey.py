import json
from unipath import Path
import pandas as pd

from tasks import match

def test_create_survey_matches_existing_survey():
    expected = json.load(open(Path(match.qualtrics_survey_dir, 'match_to_seed_1.qsf')))
    actual = match.create_survey()
    assert actual == expected

def test_create_survey_loop_merge_matches_expected():
    expected = pd.read_csv(open(Path(match.qualtrics_data_dir, 'match_to_seed_1.csv')))
    actual = match.loop_merge('match-transcriptions/selected-edited.csv',
                              version=1)
    assert actual == expected
