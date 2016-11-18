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
def render(name=None, match_dir=None, dry_run=False, cache_reset=False,
           figs_reset=False, open_after=False, ext='html'):
    """Render RMarkdown reports."""
    if match_dir and not Path(match_dir).isdir():
        # then match dir refers to glob inside reports dir
        match_dir = Path('reports/', match_dir)

    report_dir = Path(match_dir or REPORTS, name or '*.Rmd')
    reports = [Path(report) for report in glob(report_dir)]

    if dry_run:
        print '\n'.join(reports)
        return

    cmd = 'Rscript -e "rmarkdown::render(\'{}\')"'
    for report in reports:
        if cache_reset:
            _clear_cache_for_report(report)
        if figs_reset:
            _clear_figs_for_report(report)

        run(cmd.format(report))

        if open_after:
            output_file = Path(report.parent, '{}.{}'.format(report.stem, ext))
            run('open {}'.format(output_file))


def _clear_cache_for_report(report):
    report_dir = Path(report).parent
    cache_dir = Path(report_dir, '.cache')
    if cache_dir.isdir():
        print 'removing cache dir:\n\t{}'.format(cache_dir)
        cache_dir.rmtree()

def _clear_figs_for_report(report):
    report_dir = Path(report).parent
    figs_dir = Path(report_dir, 'figs')
    if figs_dir.isdir():
        print 'removing figs dir:\n\t{}'.format(figs_dir)
        figs_dir.rmtree()
