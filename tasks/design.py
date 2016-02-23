from invoke import task
import graphviz

@task
def draw_design(directory='design', output='design'):
    """Create the graph for the experimental design."""
    graph = graphviz.Graph(format='pdf', node_attr={'style': 'filled'})

    root = 'game'
    graph.node(root)

    chains = ['a', 'b', 'c', 'd']
    for chain in chains:
        graph.node(chain, label='chain ' + chain)
        graph.edge(root, chain)

    nodes_to_color = ['a0', 'b1', 'c3', 'd2']

    seeds_per_chain = 4
    for chain in chains:
        for seed in range(seeds_per_chain):
            seed_name = chain + str(seed)

            # color a subset of the seed nodes
            node_attr = {}
            if seed_name in nodes_to_color:
                node_attr['color'] = 'green'

            graph.node(seed_name, label='seed ' + seed_name, **node_attr)
            graph.edge(chain, seed_name)

    graph.render(output, directory, cleanup=True)
