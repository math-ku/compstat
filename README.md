# Computational Statistics

This repository contains slides and other materials for the course
*Computational Statistics* taught at the University of Copenhagen.

The homepage reads dates, times, and rooms from `data/timetable.csv`. To refresh
the saved KU timetable locally, run:

```sh
devenv shell -- Rscript scripts/update-timetable.R
devenv shell -- quarto render index.qmd
```

The **Update timetable** workflow runs daily at 04:23 UTC and can also be run
manually. It commits and publishes only when the dated activities change.
Timestamp and HTML formatting changes are ignored. A failed request or invalid
response fails the update and preserves the saved schedule. Website rendering
uses the saved data and does not need access to KU's server.

The update workflow calls the existing publish workflow with the new commit,
since pushes made with `GITHUB_TOKEN` do not trigger another push workflow
([GitHub documentation](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow#triggering-a-workflow-from-a-workflow)).
The daily timer becomes active when the workflow reaches the default branch.

In `index.qmd`, `session_info("2026-09-03")` selects the morning lecture on that
date. Use `"Theoretical Exercises"` as the second argument for exercise sessions,
or `afternoon = TRUE` for assignment presentations, which KU labels as lectures.
KU does not identify individual lecture topics, so this date-to-topic mapping is
explicit. If a class moves to a different date, update its call in `index.qmd`.
A missing entry displays a notice instead of assigning another class's details.

The source URL in `R/timetable.R` selects the 2026–2027 timetable for Hold 01.
Update it and the session dates when preparing a new course year. The captured
HTML in `tests/fixtures/ku-timetable.html` is a fixed parser test fixture.
