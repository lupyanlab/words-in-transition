import pandas
from .transcription_distances import summarize_transcription_distance

def test_transcription_distance_output():
    transcriptions = pandas.DataFrame(dict(
        text = ['a', 'a', 'aa'],
        message_id = [1, 1, 1],
    ))
    distances = summarize_transcription_distance(transcriptions)
    expected_cols = ('message_id text no_agreement most_freq distance '
                     'match length').split()
    assert all([exp in distances for exp in expected_cols])
