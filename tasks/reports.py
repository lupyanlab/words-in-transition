from glob import glob
from invoke import task, run
from unipath import Path

PROJ = Path(__file__).ancestor(2)


@task
def clear_cache(match=None, dry_run=False):
    report_dir = Path(PROJ, match or '**', '.cache')
    cache_dirs = glob(report_dir)
    if dry_run:
        print '\n'.join(cache_dirs)
    else:
        for d in cache_dirs:
            Path(d).rmtree()
