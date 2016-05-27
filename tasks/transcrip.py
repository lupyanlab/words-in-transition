"""Tasks dealing with transcriptions."""
from invoke import task

import pandas
import unipath

reports_dir = unipath.Path('reports')
transcrip_dir = unipath.Path(reports_dir, '4-collect-transcriptions')

@task
def label_english_words():
    import enchant
    d = enchant.Dict('en_US')

    def check_english(text):
        return all([d.check(w) for w in text.split(' ')])

    freqs_csv = unipath.Path(transcrip_dir, 'frequencies.csv')
    transcriptions = pandas.read_csv(freqs_csv)
    transcriptions['is_english'] = transcriptions.text.apply(check_english)

    out_csv = unipath.Path(transcrip_dir, 'frequencies-labeled.csv')
    transcriptions.to_csv(out_csv, index=False)
