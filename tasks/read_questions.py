import pandas as pd
from unipath import Path

from __init__ import unfold

questions = pd.read_json('../data/survey/questions.json')

for question_field in ['choices', 'given', 'survey', 'answer']:
    questions = unfold(questions, question_field)

del questions['fields']
del questions['model']
del questions['choices']

questions.rename(columns={'pk': 'question_id', 'survey': 'survey_id'}, inplace=True)

survey_info = pd.DataFrame({
    'survey_id': [1, 2, 3, 4, 12, 13],
    'survey_label': ['between', 'within', 'between', 'within', 'between-splish', 'within-splish']
})

questions = questions.merge(survey_info)

messages = pd.read_csv('../data/survey/messages.csv')

def pick_ancestor(message):
    if message in [1,2,3,4] + [138,139,140,141]:
        return message
    else:
        parent = messages.ix[messages.message_id == message, 'parent_id']
        return pick_ancestor(int(parent))

questions['answer'] = questions.given.apply(pick_ancestor)

given = messages[['message_id', 'generation', 'game_name', 'chain_name']]
given.rename(columns={'message_id': 'given', 'game_name': 'given_game', 'chain_name': 'given_chain'}, inplace=True)

questions = questions.merge(given)

questions = questions[['survey_id', 'survey_label', 'question_id', 'given', 'given_game', 'given_chain', 'generation', 'answer']]

between_game_splish_id = 3
within_game_splish_id = 138

between_splish_imitations = (questions.survey_label == "within-splish") & (questions.given_game == "between-category-game-a")
questions.ix[between_splish_imitations, 'answer'] = within_game_splish_id
within_splish_imitations = (questions.survey_label == "between-splish") & (questions.given_game == "within-category-game-a")
questions.ix[within_splish_imitations, 'answer'] = between_game_splish_id

questions.to_csv('../data/survey/questions.csv', index=False)
