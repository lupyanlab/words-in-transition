from invoke import task
import pandas as pd
from unipath import Path


@task
def read_messages():
    """Process the message models."""
    raw_data_dir = Path('data-raw')
    data_dir = Path('data')
    assert raw_data_dir.exists()

    message_model = 'grunt.Message.json'
    messages = pd.read_json(Path(raw_data_dir, message_model))

    del messages['model']

    message_model_fields = ('audio chain parent generation '
                            'rejected verified start_at end_at').split()
    unfold_model_fields(messages, message_model_fields)

    extract_from_path(messages)

    messages.sort(['game_name', 'chain_name', 'message_name'], inplace=True)

    rename_ids = dict(pk='message_id', chain='chain_id', parent='parent_id')
    messages.rename(columns=rename_ids, inplace=True)

    label_seed_messages(messages)

    messages.to_csv(Path(data_dir, 'messages.csv'), index=False)


def unfold(objects, name):
    """Pull the named value out of a list of objects."""
    return objects.apply(lambda x: x[name])


def unfold_model_fields(json_frame, fields):
    for name in fields:
        json_frame[name] = unfold(json_frame.fields, name)
    del json_frame['fields']


def extract_from_path(frame):
    splits = frame.audio.str.split('/')
    path_args = ['game_name', 'chain_name', 'message_name']
    assert len(path_args) <= len(splits[0])
    for i, name in enumerate(path_args):
        frame[name] = splits.str.get(i)


def label_seed_messages(frame):

    def find_seed(message):
        if message.generation == 0:
            return message.message_id
        parent = frame.ix[frame.message_id == message.parent_id].squeeze()
        return find_seed(parent)

    frame['seed_id'] = frame.apply(find_seed, axis=1)
