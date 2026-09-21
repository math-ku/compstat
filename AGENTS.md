# Agent Guide for Computational Statistics

This repository contains the Quarto website and course materials for
Computational Statistics at the University of Copenhagen. The course targets
graduate students with prior knowledge of statistics and R. Slides use Beamer
and XeLaTeX.

The course has four assignments, each with versions A and B: smoothing,
univariate simulation, the EM algorithm, and stochastic optimization.

## Environment and Dependencies

Run build, test, lint, and formatting commands inside the devenv environment. If
it is not already active, enter it with `devenv shell`, or run an individual
command with `devenv shell -- <command>`.

- `devenv.nix` declares R packages, Quarto, go-task, and LaTeX dependencies.
- `devenv.yaml` configures inputs; `devenv.lock` pins them. Do not modify the
  lockfile unless a dependency update explicitly requires it.
- Add missing R packages to the R wrapper in `devenv.nix`, then restart the
  shell. Do not use `install.packages()` or install R packages outside devenv.
- For LaTeX errors, check `slides/packages.tex` and confirm that the devenv
  environment is active. It provides `texliveFull`.

## Repository Layout

- `index.qmd`: course schedule and links to materials.
- `overview.qmd`, `faq.qmd`: course overview and frequently asked questions.
- `R/`: R examples and utilities.
- `slides/`: lecture sources, shared setup, and Beamer support files.
- `assignments/`: assignment descriptions.
- `exercises/`: exercise solutions.
- `data/`: course datasets and the saved timetable.
- `images/`, `assets/`: figures, bibliography, and website assets.
- `tests/`: testthat tests and fixtures.
- `scripts/`: maintenance scripts. See `README.md` for the timetable update
  workflow and the mapping between dates and topics in `index.qmd`.

Preserve existing filenames and links when editing course materials:

- Lectures use `slides/lectureN.qmd`, with lectures 1–14 and additional decks
  such as `slides/llm_use.qmd`.
- Assignments use `assignments/assignmentN.qmd`, where N is 1–4. Each file
  contains versions A and B.
- Exercise solutions use `exercises/UN.qmd`, where N identifies the week.
  Existing files include U1–U4 and U7; numbering need not be consecutive.
- Tests use `tests/test-*.R`. Other R scripts use descriptive names.

## Building and Testing

Run these commands from the repository root in the devenv environment:

  | Task                                    | Command                                    |
  | --------------------------------------- | ------------------------------------------ |
  | Preview the website                     | `task preview`                             |
  | Preview with refreshed execution caches | `task preview-refresh`                     |
  | Render for presentations                | `task render`                              |
  | Render for publishing                   | `quarto render --profile publish`          |
  | Render one document                     | `quarto render slides/lecture1.qmd`        |
  | Run the R tests                         | `Rscript -e "testthat::test_dir('tests')"` |

`Taskfile.yml` defines the preview and render tasks. `task render` uses the
`present` profile. Both `_quarto-present.yml` and `_quarto-publish.yml` disable
execution caching; the publish profile also produces Beamer handouts.
`_quarto.yml` holds the shared website and format configuration and enables
execution caching by default. Use the preview-refresh task when cached output is
stale.

Preview or render changed `.qmd` files before committing. When changing R code
used by a document, also validate that document. Standalone R changes do not
require rebuilding unrelated website pages.

The tests include basic teaching examples and regression coverage for density
estimation, gradient descent, momentum, lecture optimization examples, the
patched `bench` package, and timetable handling. Run relevant tests when
changing those implementations; use the command above for the full suite.

Quarto writes the site to `_site/` and project state to `.quarto/`. Both are
ignored by Git; do not commit generated site or cache files.

`.github/workflows/publish.yml` renders with the publish profile, checks links,
and deploys to GitHub Pages. It runs on pushes to `main`, manual dispatch, and
calls from other workflows.

## Linting and Formatting

Use Arity for R and Panache for Markdown and Quarto. Their configuration files
are `arity.toml` and `panache.toml`. Panache uses Arity to format and lint R
code blocks and clang-format to format C++ blocks. `.clang-format` selects the
Mozilla style.

Run the tools on the files you change. For example:

```bash
arity format R/kernel.R
arity lint R/kernel.R
panache format slides/lecture1.qmd
panache lint slides/lecture1.qmd
```

Add `--check` to either `format` command to check formatting without changing
files. Panache excludes `AGENTS.md` during directory traversal; pass the file
explicitly when checking or formatting it.

## R Code and Data

Use `here::here()` for file paths in R code so they resolve from the project
root. For example:

```r
read.table(here::here("data", "phipsi.tsv"), header = TRUE)
```

In Quarto, use chunk options to control execution and presentation:

````qmd
```{r chunk-name}
#| echo: true
#| eval: false
#| message: false

# R code here
```
````

## Slide Conventions

`slides/_metadata.yml` sets the shared Beamer metadata and selects
`beamer-overlays.lua`. `slides/_common.qmd` contains the shared R setup and plot
hooks. LaTeX packages live in `slides/packages.tex`; `slides/passoptions.latex`
and `slides/tightlist.tex` customize the template.

- Use figures liberally. Avoid bullet points unless actually listing something,
  and use `\pause` to reveal content incrementally.
- Separate paragraphs with `\medskip` or `\bigskip`. Blank lines alone do not
  provide enough vertical spacing.
- Raw LaTeX is allowed. For animated figures, use pre-made figures with
  `xmpmulti`. The shared setup also supports `fig-show: animate` in R chunks
  through an `xmpmulti` plot hook.
- Use `algorithm2e` with raw LaTeX for algorithms.
- Use LaTeX commands for mathematical symbols, such as `\sum` and `\int`, rather
  than Unicode symbols.
- Use `\pdfpcnote{}` for speaker notes. Write notes as lists, with each item
  beginning with `-` and ending with `\\`. No more than 3 short notes per slide.

### Plots

Keep plots simple and clean. Use ggplot2 when it makes sense; base R plots are
also fine.

- Prefer colors such as `"darkorange"` and `"royalblue"`, or palettes from
  ColorBrewer, Tableau, or Viridis.
- Avoid modifying line width (`lwd`).
- Do not add themes. `slides/_common.qmd` sets the theme globally.
- Use `expression()` for mathematical notation in axis labels and titles.
- A figure width of about 5 inches and height of 3 inches spans the entire slide.
  The defaults are 2.8 by 2.1 inches, suitable for a plot in one column.
