# Agent Guide for Computational Statistics Repository

## Repository Overview

This is a course website repository for the Computational Statistics course at
the University of Copenhagen. The repository generates a static website with
course materials including lecture slides (PDF presentations), assignments,
exercises, and course information.

**Repository Type:** Academic course website (Quarto-based static site
generator) **Primary Language:** R (58 R files), Quarto Markdown (30 .qmd files)
**Repository Size:** \~63 MB **Total Source Files:** \~101 files (.R, .qmd,
.yml, .yaml, .md) **Target Audience:** Graduate students with prerequisite
knowledge of statistics and R

### Course Structure

The course has exactly **4 assignments**, each with two versions (A and B). The
four main topics are:

1. Smoothing
2. Univariate Simulation
3. The EM Algorithm
4. Stochastic Optimization

### Key Course Files

- **index.qmd** - Course schedule with links to slides, assignments, exercises,
  and readings
- **overview.qmd** - Complete course overview including topics, structure, and
  literature
- **faq.qmd** - Frequently asked questions about the course

## Technology Stack

- **Build Tool:** Quarto (Quarto Markdown for content, renders to HTML/PDF)
- **Environment Manager:** devenv (Nix-backed, reproducible environment)
- **Task Runner:** go-task (Taskfile.yml)
- **Runtime:** R with extensive package ecosystem
- **PDF Generation:** XeLaTeX via Quarto (for Beamer slides)
- **CI/CD:** GitHub Actions (publishes to GitHub Pages)

### Key R Packages (from devenv.nix)

The environment includes: tidyverse, ggplot2, Rcpp, RcppArmadillo, bench,
testthat, knitr, rmarkdown, here, lme4, profvis, foreach, doParallel, CSwR
(course-specific package from GitHub), and many others.

## Project Structure

### Root Directory Layout

```
/
├── .github/workflows/     # CI/CD pipelines
├── R/                     # R scripts (examples, exercises, utilities)
├── slides/                # Lecture slides (.qmd → .pdf via Quarto)
├── assignments/           # Assignment descriptions (.qmd)
├── exercises/             # Exercise solutions (.qmd)
├── data/                  # Course datasets (CSV, txt, RData files)
├── images/                # Images, diagrams, logos
├── assets/                # Additional assets (bibliography, images)
├── tests/                 # R test files (test-*.R)
├── _quarto.yml           # Main Quarto configuration
├── _quarto-present.yml   # Quarto profile for presentations
├── _quarto-publish.yml   # Quarto profile for publishing
├── devenv.nix            # Development environment and dependencies
├── devenv.yaml           # devenv inputs
├── devenv.lock           # Locked environment inputs
├── Taskfile.yml          # Task definitions
├── index.qmd             # Course homepage
└── *.qmd                 # Other top-level pages
```

### Important Configuration Files

1. **devenv.nix** - Development environment with all dependencies (R packages,
   Quarto, go-task, LaTeX)
2. **devenv.yaml** - devenv input configuration
3. **devenv.lock** - Locked environment inputs
4. **_quarto.yml** - Main Quarto configuration (website structure, themes,
   formats)
5. **_quarto-present.yml** - Disables caching for presentations
6. **_quarto-publish.yml** - Handout mode for published content
7. **Taskfile.yml** - Task definitions for preview and render
8. **.lintr** - R linting configuration (excludes some strict rules)
9. **.prettierrc.yml** - Prose wrapping configuration
10. **.clang-format** - C++ code formatting configuration (uses Mozilla style)
11. **air.toml** - R code formatting configuration (follows tidyverse style)

### Slides Directory Structure

```
slides/
├── _common.qmd          # Shared setup for all slides
├── _metadata.yml        # Default metadata for slides
├── beamer-overlays.lua  # Quarto filter for Beamer
├── lecture[1-14].qmd    # Individual lecture files
├── packages.tex         # LaTeX packages for slides
├── passoptions.latex    # Overrides quarto partial for LaTeX output
└── tightlist.tex        # List formatting template
```

## Build and Development Workflow

### Prerequisites

**CRITICAL:** This repository requires Nix and devenv to be installed. All other
dependencies (R, Quarto, go-task, LaTeX) are provided through devenv.

### Environment Setup

The repository uses devenv for a reproducible development environment. Enter it
manually with:

```bash
devenv shell
```

For a single noninteractive command, use `devenv shell -- <command>`. If your
shell is configured to activate devenv automatically when entering the project,
you can run project commands directly.

**Environment Setup Time:** First run takes 5-15 minutes to download and build
dependencies. Subsequent runs are instant due to Nix caching.

### Building the Website

**ALWAYS run commands inside the devenv environment.**

#### Preview the Website (Development)

```bash
# Option 1: Using go-task
task preview

# Option 2: Direct Quarto command
quarto preview

# With cache refresh (if you encounter caching issues)
task preview-refresh
# OR
quarto preview --cache-refresh
```

**Expected behavior:** Starts a development server, typically on
http://localhost:XXXX. The preview auto-reloads on file changes.

#### Render the Website (Production)

```bash
# For presentations (with caching disabled)
task render
# OR
quarto render --profile present

# For publishing (handout mode, no caching)
quarto render --profile publish
```

**Expected behavior:** Generates all HTML pages and PDF slides into `_site/`
directory. Rendering all slides takes approximately 5-10 minutes due to PDF
generation via LaTeX.

**Output Location:** `_site/` directory (ignored by .gitignore)

### Testing

The repository includes minimal test files in the `tests/` directory:

- `tests/test-mean.R` - Basic R test using testthat
- `tests/test-sum.R` - Basic R test using testthat

**Running Tests:**

```bash
# Inside the devenv environment
Rscript -e "testthat::test_dir('tests')"
```

**Note:** These are example tests. The repository does not have comprehensive
test coverage or a dedicated test runner.

### Linting and Formatting

- arity: R code formatting and linting
- panache: markdown adn quarto formatting and linting
- clang-format: C++ code formatting

Panache uses arity and clang-format to format Quarto code blocks.

## CI/CD Pipeline

### GitHub Actions Workflow (.github/workflows/publish.yml)

**Trigger:** Push to `main` branch or manual workflow_dispatch

**Steps:**

1. Checkout repository
2. Install Nix (cachix/install-nix-action@v31)
3. Set up the Cachix cache (cache name: jolars)
4. Install devenv
5. Configure GitHub Pages
6. Restore git timestamps (important for caching)
7. **Build:** `devenv shell -- quarto render --profile publish`
8. Check links
9. Upload the artifact to GitHub Pages
10. Deploy to GitHub Pages

**Build Time:** Approximately 10-15 minutes (with cache hits)

**Important:** The workflow restores git timestamps before building. This
ensures Quarto's caching works correctly across CI runs.

## Common Tasks and Workflows

### Modifying R Scripts

1. R scripts in `R/` are standalone examples/exercises
2. Scripts should use `here::here()` for path resolution
3. Test scripts interactively in an R console within the devenv environment
4. No need to rebuild website unless scripts are referenced in .qmd files

### Working with Data

- All datasets are in `data/` directory
- Always use `here::here("data", "filename")` in R code for path resolution
- Example: `read.table(here::here("data", "phipsi.tsv"), header = TRUE)`

## Known Issues and Workarounds

### Issue: Quarto Caching Problems

**Symptom:** Old content appears or changes don't reflect

**Solution:** Use cache refresh:

```bash
quarto preview --cache-refresh
# OR
task preview-refresh
```

### Issue: LaTeX/PDF Generation Fails

**Symptom:** Errors during slide rendering mentioning XeLaTeX or missing
packages

**Solution:**

- Ensure you're in the devenv environment (all LaTeX packages are included via
  texliveFull)
- Check `slides/packages.tex` for required LaTeX packages
- All required packages should be available in the devenv environment

### Issue: R Package Not Found

**Symptom:** Error loading R package during rendering

**Solution:**

1. Check if the package is listed in `devenv.nix` under the R wrapper packages
2. If missing, add it to the list and restart `devenv shell`
3. Do NOT install packages via `install.packages()` - all dependencies must be
   declared in `devenv.nix`

### Issue: Git Timestamp Issues in CI

**Note:** The CI workflow uses `chetan/git-restore-mtime-action@v2` to restore
timestamps. This is intentional and should not be removed, as it helps Quarto's
caching mechanism work correctly.

## File Patterns and Conventions

### Quarto Document Structure

Most .qmd files follow this pattern:

```qmd
---
title: "Document Title"
format: html  # or beamer for slides
---

Content goes here...
```

### Slide Presentation Guidelines

- The presentation style makes liberal use of figures. Avoid bullet
  points unless actually listing something. Use pauses liberally to incrementally
  show content.
- Paragraphs need `\medskip` or `\bigskip` to create vertical spacing between them.
  Separating paragraphs with blank lines is **not sufficient**.
- Use `\pause` for pausing.
- Raw LaTeX commands are allowed and commonly used in slides
- For animated figures, use raw LaTeX code with pre-made figures and the
  `xmpmulti` package
- For algorithms, use the `algorithm2e` package with raw LaTeX code
- **DO NOT** use unicode characters for mathematical symbols (e.g., ∑, ∫). Always
  use LaTeX syntax (e.g., `\sum`, `\int`).
- Use `\pdfpcnote{}` for speaker notes. Write them as lists, beginning with `-` and
  ending with `\\`. No more than say 5-6 lines per slide. Avoid long paragraphs.

#### Plots

Keep plots simple and clean. Use ggplot2 if it makes sense, otherwise base R
plots are fine.

In particular:

- Try to use modern colors for the plots, for instance `"darkorange"` and
  `"royalblue`, and palettes from ColorBrewer, Tableau, or Viridis.
- Avoid modifying line width (`lwd`).
- Don't add any themes. They are set globally in `slides/_common.qmd`.
- Use `expression()` for mathematical notation in axis labels and titles.
- For ggplot2 plots, a width of around 5 inches spans the entire slide width and
  a height of 3 inches spans the height well. Defaults are 2.8 and 2.1 for width
  and height respectively, which is good for a one-column plot.

### R Code in Quarto

````qmd
```{r chunk-name}
#| echo: true
#| eval: false
#| message: false

# R code here
```
````

Common chunk options: `echo`, `eval`, `message`, `warning`, `fig-width`,
`fig-height`, `cache`

### File Naming

- Lectures: `lectureN.qmd` where N is 1-14
- Assignments: `assignmentN.qmd` where N is 1-4 (each has two versions: A and B)
- Exercises: `UN.qmd` where N is 1-4 (U for "Ugeopgave" = exercise in Danish)
- Tests: `test-*.R`
- R scripts: descriptive names, often matching lecture topics

## Dependencies Not Obvious from Structure

**LaTeX Packages:** Extensive list in `slides/packages.tex` (xmpmulti,
fontsetup, algorithm2e, tikz libraries, etc.)

## Quick Reference Commands

All commands should be run inside the devenv environment. Enter it with
`devenv shell`, or prefix an individual command with `devenv shell --`:

```bash
# Preview website (dev server with auto-reload)
task preview
quarto preview

# Render for presentation
task render
quarto render --profile present

# Render for publishing
quarto render --profile publish

# Render specific file
quarto render slides/lecture1.qmd

# Run R tests
Rscript -e "testthat::test_dir('tests')"

# Lint R code
Rscript -e "lintr::lint_dir('R')"

# Start R console with all packages
R
```

## Critical Instructions for Agents

1. **ALWAYS use the devenv environment:** Run build and test commands from an
   active `devenv shell`, or use `devenv shell -- <command>`. Without this, the
   correct R, Quarto, and other tools may not be available.

2. **DO NOT modify `devenv.lock` unless a dependency update explicitly requires
   it:** This file pins the reproducible environment.

3. **DO NOT install R packages outside of devenv:** All R package dependencies
   must be declared in `devenv.nix`. Do not use `install.packages()`.

4. **ALWAYS use `here::here()` for file paths in R code:** This ensures scripts
   work regardless of working directory.

5. **DO NOT remove timestamp restoration in CI:** The `git-restore-mtime-action`
   is critical for Quarto caching.

6. **Test rendering before committing:** Always preview or render changed .qmd
   files to ensure they compile correctly.

7. **Respect existing file structure:** Lectures, assignments, and exercises
   follow strict naming conventions referenced in index.qmd.

8. **Cache directory (.quarto/) is ignored:** Don't commit cache files.

9. **Generated site (\_site/) is ignored:** This directory is regenerated on
   each build.
