import json
import pandas

def make_edges(grunt_Message_json):
    messages = pandas.read_json(grunt_Message_json)

    def unfold(key):
        messages[key] = messages.fields.apply(lambda x: x[key])

    for key in messages.fields.iloc[0].keys():
        unfold(key)

    messages.rename(
        columns=dict(pk='message_id', chain='chain_id', parent='parent_id'),
        inplace=True,
    )

    def extract_from_path(frame):
        splits = frame.audio.str.split('/')
        path_args = ['game_name', 'category', 'imitation_name']
        assert len(path_args) <= len(splits[0])
        for i, name in enumerate(path_args):
            frame[name] = splits.str.get(i)

    extract_from_path(messages)

    messages = messages.ix[
        (messages.game_name == 'words-in-transition') &
        (messages.rejected == False)
    ]

    root_edges = pandas.DataFrame({
        'x': 'root', 'y': ['glass', 'tear', 'water', 'zipper'],
    })

    seed_edges = messages.ix[
        (messages.generation == 0),
        ['category', 'message_id']
    ].rename(columns={'category': 'x', 'message_id': 'y'})
    seed_edges['y'] = seed_edges.y.astype(str)

    imitation_edges = messages.ix[
        (messages.parent_id.notnull()),
        ['message_id', 'parent_id']
    ].rename(columns={'message_id': 'y', 'parent_id': 'x'})
    imitation_edges['x'] = imitation_edges.x.astype(int).astype(str)
    imitation_edges['y'] = imitation_edges.y.astype(str)

    edges = pandas.concat([root_edges, seed_edges, imitation_edges],
                          ignore_index=True)

    # Verify that all edges lead back to the root node
    def find_root(message):
        parent = edges.ix[edges.y == message.x].squeeze()
        if len(parent) == 0:
            return message.x
        return find_root(parent)
    assert all(edges.apply(find_root, axis=1) == 'root')

    # Fill edges of each branch out to 8 generations
    generations = messages.copy()
    generations['message_id'] = generations.message_id.astype(str)
    generations = generations.set_index('message_id')['generation'].to_dict()

    fill_edges = []
    for edge in imitation_edges.itertuples():
        children = imitation_edges.ix[imitation_edges.x == edge.y]
        if len(children) == 0:
            # This node has no children
            last_node = edge.y
            last_generation = generations[edge.y]
            for fill_gen in range(last_generation+1, 9):
                new_node = '{}-{}'.format(last_node, fill_gen)
                new_edge = (last_node, new_node)
                fill_edges.append(new_edge)
                last_node = new_node
    fill_edges = pandas.DataFrame.from_records(fill_edges, columns=['x', 'y'])

    fill_edges['edge_type'] = 'invis'
    edges['edge_type'] = 'vis'
    edges = pandas.concat([edges, fill_edges], ignore_index=True)

    # Verify that all edges lead back to the root node
    def find_root(message):
        parent = edges.ix[edges.y == message.x].squeeze()
        if len(parent) == 0:
            return message.x
        return find_root(parent)
    assert all(edges.apply(find_root, axis=1) == 'root')
    return edges
