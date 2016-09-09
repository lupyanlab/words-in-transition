from difflib import SequenceMatcher

import pandas


def summarize_transcription_distance(transcriptions):
    distances = (transcriptions.groupby('message_id')
                               .apply(distance_to_most_frequent))

    return distances


def distance_to_most_frequent(transcriptions):
    """Calculate distance to the most frequent transcription."""
    output = 'message_id text no_freq most_freq distance match length'.split()

    frequencies = transcriptions.text.value_counts()
    most_frequent = frequencies.index[0]
    most_frequent_frequency = frequencies.iloc[0]

    # Label the transcriptions for which there was no agreement
    transcriptions['no_freq'] = int(most_frequent_frequency == 1)

    transcriptions['most_freq'] = most_frequent
    matcher = SequenceMatcher()
    matcher.set_seq1(most_frequent)

    distancer_vars = 'distance match length'.split()

    def distancer(seq2):
        matcher.set_seq2(seq2)
        distance = matcher.ratio()

        match = matcher.find_longest_match(0, len(matcher.a), 0, len(matcher.b))
        length = match.size
        substr = matcher.a[match.a:match.a+length]

        return pandas.Series([distance, match, length], index=distancer_vars)

    transcriptions = transcriptions.join(transcriptions.text.apply(distancer))
    return transcriptions[output]
