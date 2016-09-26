from glob import glob
from invoke import task, run
from unipath import Path

PROJ = Path(__file__).ancestor(2)
REPORTS = Path(PROJ, 'reports')


@task
def clear_cache(match=None, dry_run=False):
    """Reset knitr cache directories."""
    report_dir = Path(PROJ, match or '**', '.cache')
    cache_dirs = glob(report_dir)
    if dry_run:
        print '\n'.join(cache_dirs)
    else:
        for d in cache_dirs:
            Path(d).rmtree()


@task
def render(match=None, name=None, dry_run=False, clear_cache=False):
    """Render RMarkdown reports."""
    report_dir = Path(REPORTS, name or '*.Rmd')
    reports = glob(report_dir)

    if dry_run:
        print '\n'.join(reports)
        return

    cmd = 'Rscript -e "rmarkdown::render(\'{}\')"'
    for report in reports:
        if clear_cache:
            _clear_cache_for_report(report)
        run(cmd.format(report))


def _clear_cache_for_report(report):
    report_dir = Path(report).parent
    cache_dir = Path(report_dir, '.cache')
    if cache_dir.isdir():
        print 'removing cache dir:\n\t{}'.format(cache_dir)
        cache_dir.rmtree()
