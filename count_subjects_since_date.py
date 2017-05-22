from __future__ import print_function
from unipath import Path
import pandas

july_1 = pandas.to_datetime('2016-07-01')

total_subjs = 0

for subjs_csv in Path('wordsintransition/data-raw/subjects').listdir('*.csv'):
    subjs = pandas.read_csv(subjs_csv)
    subjs['Time'] = pandas.to_datetime(subjs.SubmitTime)
    n_subjs_after_time = len(subjs.ix[subjs.Time > july_1])
    print('{}: {}'.format(subjs_csv.name, n_subjs_after_time))
    total_subjs += n_subjs_after_time

print(total_subjs)
