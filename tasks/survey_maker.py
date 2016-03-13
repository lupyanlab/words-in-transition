import pandas as pd
import json

import random

def create_surveys_a():
    messages = pd.read_csv('messages-cleaned.csv')

    # Remove messages that are null in the to_remove column
    messages = messages.ix[messages.to_remove.notnull()]

    # Remove messages that shouldn't be used in the surveys
    messages = messages.ix[messages.to_remove == 0]

    # Split seed messages from imitations
    seeds = messages.ix[messages.generation == 0]
    imitations = messages.ix[messages.generation != 0]

    between_game_name = 'between-category-game-a'
    between_survey = {}
    between_survey['choices'] = seeds.ix[seeds.game_name == between_game_name, 'message_id'].tolist()
    between_survey['given'] = imitations.ix[imitations.game_name == between_game_name, 'message_id'].tolist()
    with open('between_survey_a.json', 'w') as f:
        f.write(json.dumps(between_survey))

    within_game_name = 'within-category-game-a'
    within_survey = {}
    within_survey['choices'] = seeds.ix[seeds.game_name == within_game_name, 'message_id'].tolist()
    within_survey['given'] = imitations.ix[imitations.game_name == within_game_name, 'message_id'].tolist()
    with open('within_survey_a.json', 'w') as f:
        f.write(json.dumps(within_survey))

    return between_survey, within_survey

def create_surveys_b():
    messages = pd.read_csv('messages-cleaned.csv')

    # Split off the seeds
    seeds = messages.ix[messages.generation == 0]

    # Select only the messages that are null in the to_remove column
    # These messages are valid recordings that are not seeds and have
    # not been tested in a survey
    imitations = messages.ix[messages.to_remove.isnull()]

    between_game_name = 'between-category-game-a'
    between_survey = {}
    between_survey['choices'] = seeds.ix[seeds.game_name == between_game_name, 'message_id'].tolist()
    between_survey['given'] = imitations.ix[imitations.game_name == between_game_name, 'message_id'].tolist()
    with open('between_survey_b.json', 'w') as f:
        f.write(json.dumps(between_survey))

    within_game_name = 'within-category-game-a'
    within_survey = {}
    within_survey['choices'] = seeds.ix[seeds.game_name == within_game_name, 'message_id'].tolist()
    within_survey['given'] = imitations.ix[imitations.game_name == within_game_name, 'message_id'].tolist()
    with open('within_survey_b.json', 'w') as f:
        f.write(json.dumps(within_survey))

    return between_survey, within_survey

def create_surveys_c():
    """ In this survey people are given imitations from the between-category-game-a
    and choices from the within-category-game."""
    messages = pd.read_csv('messages-cleaned.csv')

    # Get rid of bad recordings
    messages['to_remove'] = messages.to_remove.fillna(0)
    messages = messages.ix[messages.to_remove == 0]

    # Split off the seeds
    seeds = messages.ix[messages.generation == 0]
    imitations = messages.ix[messages.generation != 0]

    between_game_name = 'between-category-game-a'
    within_game_name = 'within-category-game-a'

    between_choices = seeds.ix[seeds.game_name == between_game_name, 'message_id'].tolist()
    within_choices = seeds.ix[seeds.game_name == within_game_name, 'message_id'].tolist()

    between_imitations = imitations.ix[(imitations.game_name == between_game_name) & (imitations.chain_name != 'splish'), 'message_id'].tolist()
    within_imitations = imitations.ix[(imitations.game_name == within_game_name)  & (imitations.chain_name != 'splish'), 'message_id'].tolist()

    between_splish = imitations.ix[(imitations.game_name == between_game_name) & (imitations.chain_name == 'splish'), 'message_id'].tolist()
    within_splish = imitations.ix[(imitations.game_name == within_game_name) & (imitations.chain_name == 'splish'), 'message_id'].tolist()

    # select imitations at random because we don't have time to collect all ratings
    random.seed(100)

    all_between_given = between_splish + within_splish + random.sample(between_imitations, 100)

    between_plus_within_splish = {}
    between_plus_within_splish['choices'] = between_choices
    between_plus_within_splish['given'] = all_between_given

    with open('between_survey_with_within_splish.json', 'w') as f:
        f.write(json.dumps(between_plus_within_splish))

    all_within_given = within_splish + between_splish + random.sample(within_imitations, 100)

    within_plus_between_splish = {}
    within_plus_between_splish['choices'] = within_choices
    within_plus_between_splish['given'] = all_within_given

    with open('within_survey_with_between_splish.json', 'w') as f:
        f.write(json.dumps(within_plus_between_splish))

    return between_plus_within_splish, within_plus_between_splish


if __name__ == '__main__':
    a1, a2 = create_surveys_a()
    b1, b2 = create_surveys_b()
    b, w = create_surveys_c()
