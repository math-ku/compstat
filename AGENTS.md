# Agent Guide for Computational Statistics Repository

## Repository Overview

This is a course website repository for the Computational Statistics course at
the University of Copenhagen. The repository generates a static website with
course materials including lecture slides (PDF presentations), assignments,
exercises, and course information.

**Repository Type:** Academic course website (Quarto-based static site
generator) **Primary Language:** R (58 R files), Quarto Markdown (30 .qmd files)
**Repository Size:** ~63 MB **Total Source Files:** ~101 files (.R, .qmd, .yml,
.yaml, .md) **Target Audience:** Graduate students with prerequisite knowledge
of statistics and R

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
- **Package Manager:** Nix (flake-based, for reproducible environment)
- **Task Runner:** go-task (Taskfile.yml)
- **Runtime:** R with extensive package ecosystem
- **PDF Generation:** XeLaTeX via Quarto (for Beamer slides)
- **CI/CD:** GitHub Actions (publishes to GitHub Pages)

### Key R Packages (from flake.nix)

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
├── scripts/               # Utility scripts (Python converter)
├── _quarto.yml           # Main Quarto configuration
├── _quarto-present.yml   # Quarto profile for presentations
├── _quarto-publish.yml   # Quarto profile for publishing
├── flake.nix             # Nix flake for environment
├── Taskfile.yml          # Task definitions
├── index.qmd             # Course homepage
└── *.qmd                 # Other top-level pages
```

### Important Configuration Files

1. **flake.nix** - Nix development environment with all dependencies (R
   packages, Quarto, go-task, LaTeX)
2. **\_quarto.yml** - Main Quarto configuration (website structure, themes,
   formats)
3. **\_quarto-present.yml** - Disables caching for presentations
4. **\_quarto-publish.yml** - Handout mode for published content
5. **Taskfile.yml** - Task definitions for preview and render
6. **.lintr** - R linting configuration (excludes some strict rules)
7. **.prettierrc.yml** - Prose wrapping configuration
8. **.clang-format** - C++ code formatting configuration (uses Mozilla style)
9. **air.toml** - R code formatting configuration (follows tidyverse style)
10. **.envrc** - direnv configuration for automatic Nix environment loading

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

**CRITICAL:** This repository requires Nix to be installed. All other
dependencies (R, Quarto, go-task, LaTeX) are provided through the Nix flake.

### Environment Setup

The repository uses Nix flakes for reproducible development environments. There
are two ways to enter the environment:

1. **Manual (every time):**

   ```bash
   nix develop
   ```

2. **Automatic (recommended with direnv):** Install direnv and nix-direnv, then
   run `direnv allow` in the repository root. The environment will automatically
   load when entering the directory.

**Environment Setup Time:** First run takes 5-15 minutes to download and build
dependencies. Subsequent runs are instant due to Nix caching.

### Building the Website

**ALWAYS run commands inside the Nix development environment** (either via
`nix develop` or direnv).

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
# Inside nix develop environment
Rscript -e "testthat::test_dir('tests')"
```

**Note:** These are example tests. The repository does not have comprehensive
test coverage or a dedicated test runner.

### Linting and Formatting

**R Code Linting:**

```bash
# Inside nix develop environment
Rscript -e "lintr::lint_dir('R')"
Rscript -e "lintr::lint_dir('slides')"
```

Configuration is in `.lintr` which excludes: cyclocomp_linter,
implicit_integer_linter, undesirable_function_linter, object_length_linter,
object_name_linter.

**R Code Formatting:** Use the `air` formatter which follows the tidyverse style
guide:

```bash
# Inside nix develop environment
# Configuration in air.toml
air format R/gd.R # to format a specific file
```

**C++ Code Formatting:** Folow the Mozilla style. clang-format is not available
in the nix development environment.

**Note:** No automated linting is enforced in CI.

## CI/CD Pipeline

### GitHub Actions Workflow (.github/workflows/publish.yml)

**Trigger:** Push to `main` branch or manual workflow_dispatch

**Steps:**

1. Checkout repository
2. Install Nix (cachix/install-nix-action@v31)
3. Setup Cachix cache (cache name: jolars)
4. Configure GitHub Pages
5. Restore git timestamps (important for caching)
6. **Build:** `nix develop --command quarto render --profile publish`
7. Upload artifact to GitHub Pages
8. Deploy to GitHub Pages

**Build Time:** Approximately 10-15 minutes (with cache hits)

**Important:** The workflow restores git timestamps before building. This
ensures Quarto's caching works correctly across CI runs.

## Common Tasks and Workflows

### Adding a New Lecture Slide

1. Create `slides/lectureX.qmd`
2. Include common setup: `{{< include _common.qmd >}}`
3. Use YAML frontmatter:

   ```yaml
   ---
   title: "Your Lecture Title"
   ---

   ```

4. Render to test: `quarto render slides/lectureX.qmd`
5. PDF output: `slides/lectureX.pdf`

### Adding a New Assignment

**Note:** There are exactly 4 assignments in the course, each with two versions
(A and B). Do not add more unless explicitly requested.

1. Create `assignments/assignmentX.qmd` where X is 1-4
2. Each assignment covers one of the four main topics
3. Reference in `index.qmd` schedule
4. Preview changes: `task preview`

### Modifying R Scripts

1. R scripts in `R/` are standalone examples/exercises
2. Scripts should use `here::here()` for path resolution
3. Test scripts interactively in R console within nix develop environment
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

- Ensure you're in the Nix environment (all LaTeX packages included via
  texliveFull)
- Check `slides/packages.tex` for required LaTeX packages
- All required packages should be available in the Nix environment

### Issue: R Package Not Found

**Symptom:** Error loading R package during rendering

**Solution:**

1. Check if package is listed in `flake.nix` under `pkgs.rPackages`
2. If missing, add it to the list and run `nix develop` again (may need to exit
   and re-enter)
3. Do NOT install packages via `install.packages()` - all dependencies must be
   in flake.nix

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

**Important:** The presentation style makes liberal use of figures. Avoid bullet
points unless actually listing something. Use pauses liberally to incrementally
show content.

For slides:

```qmd
---
title: "Lecture Title"
---

{{< include _common.qmd >}}

## Section 1

Content...

. . .

More content (pause in Beamer)...

##

Empty title frame (using ## without title)
```

**Pause Mechanisms:**

- Use `. . .` (three dots with spaces) for pauses in Quarto
- Use `\pause` for raw LaTeX pauses
- Both methods work and are used throughout the slides

**Raw LaTeX Commands:**

- Raw LaTeX commands are allowed and commonly used in slides
- For animated figures, use raw LaTeX code with pre-made figures and the
  `xmpmulti` package
- For algorithms, use the `algorithm2e` package with raw LaTeX code

**Example with LaTeX:**

```qmd
\pause

\begin{algorithm}[H]
  % algorithm content
\end{algorithm}
```

**DO NOT** use unicode characters for mathematical symbols (e.g., ∑, ∫). Always
use LaTeX syntax (e.g., `\sum`, `\int`).

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

1. **CSwR Package:** Custom R package from GitHub (nielsrhansen/CSwR) built as
   part of Nix flake
2. **LaTeX Packages:** Extensive list in `slides/packages.tex` (xmpmulti,
   fontsetup, algorithm2e, tikz libraries, etc.)

## Quick Reference Commands

All commands should be run inside `nix develop` environment:

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

1. **ALWAYS enter the Nix development environment first:** Run `nix develop`
   before any build/test commands. Without this, R, Quarto, and other tools will
   not be available.

2. **DO NOT modify flake.nix and NEVER flake.lock unless explicitly required:**
   These files define the reproducible environment. Changes can break the build
   for all users.

3. **DO NOT install R packages outside of flake.nix:** All R package
   dependencies must be declared in flake.nix. Do not use `install.packages()`.

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

10. **When in doubt, trust these instructions:** Only search for additional
    information if instructions here are incomplete or incorrect. The workflow
    described here is the authoritative method for working with this repository.
