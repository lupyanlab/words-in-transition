from glob import glob
from invoke import task, run
from unipath import Path

PROJ = Path(__file__).ancestor(2)
REPORTS = Path(PROJ, 'reports')


@task
def clear(match=None, dry_run=False, x_cache_files=None):
    """Reset knitr cache directories and remove figures."""
    report_dir = Path(PROJ, match or '**', '.cache')
    fig_dir = Path(PROJ, match or '**', 'figs')

    dirs_to_remove = glob(report_dir) + glob(fig_dir)
    if dry_run:
        print '\n'.join(dirs_to_remove)
        return

    for d in dirs_to_remove:
        if x_cache_files is not None:
            for x in Path(d).listdir(x_cache_files):
                print 'removing {}'.format(x)
                x.remove()
        else:
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
