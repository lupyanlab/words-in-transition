from invoke import task, run
from unipath import Path

from .parse import responses

r_pkg_dir = Path('wordsintransition')

@task(responses)
def use_data():
    """Run the use_data script in the wordsintransition R package."""
    cmd = "cd {} && Rscript data-raw/use-data.R"
    run(cmd.format(r_pkg_dir))
