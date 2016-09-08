import enchant

ENGLISH = enchant.Dict('en_US')


def summarize_transcription_frequency(transcriptions):
    frequencies = transcriptions.ix[transcriptions.is_catch_trial == 0]
    frequencies.loc[:, 'text'] = frequencies.text.str.lower()
    groupers = ['chain_name', 'seed_id', 'message_id',
                'transcription_survey_name']
    frequencies = (frequencies.groupby(groupers)
                              .text
                              .value_counts()
                              .reset_index()
                              .rename(columns={0: 'n'}))
    frequencies['is_english'] = frequencies.text.apply(check_english).astype(int)
    return frequencies

def check_english(text):
    text = ' '.join(text.split())  # remove variable white space
    return all([ENGLISH.check(w) for w in text.split()])
