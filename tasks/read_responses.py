import pandas as pd

from __init__ import unfold

responses = pd.read_json('../data/survey/responses.json')

for response_field in ['selection', 'question']:
    responses = unfold(responses, response_field)

del responses['fields']

responses = responses[['selection', 'question']]
responses.rename(columns={'question': 'question_id'}, inplace=True)

questions = pd.read_csv('../data/survey/questions.csv')

responses = responses.merge(questions)

responses = responses[[
    'survey_id', 'survey_label',
    'question_id', 'given', 'generation', 'given_game', 'given_chain',
    'answer', 'selection',
]]

responses.to_csv('../data/responses.csv', index=False)
