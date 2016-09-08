import pandas
from .transcription_distances import summarize_transcription_distance

def test_transcription_distance_output():
    transcriptions = pandas.DataFrame(dict(
        text = ['a', 'a', 'aa'],
        message_id = [1, 1, 1],
    ))
    distances = summarize_transcription_distance(transcriptions)
    expected_cols = ['message_id', 'no_freq', 'most_freq', 'text', 'distance']
    assert all([exp in distances for exp in expected_cols])
