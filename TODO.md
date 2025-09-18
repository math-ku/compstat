---
title: Course Improvements
format: html
---

## General

- Harmonize notation with book
- Tone down emphasis on object oriented programming.
- Reconsider reading instructions; maybe not aligned properly.

### Interesting Topics that Could Be Covered

- Gibbs sampling
- Autodifferentiation
- Two-dimensional kernel density estimation

## Lecture 1: Introduction

- Maybe add one example for each topic covered in the course, aligned with the
  book.

## Lecture 3: Measuring and Improving Performance

- Add another exercise.
- Introduce garbage collection before the benchmarking.
- Expand material on memory management.
- Make binning part clearer: add illustrations and skip the implementation
  altogether.
- Say something about sparse matrices.
- Maybe add something about GPU computing.

## Lecture 4: Parallelization and Scatterplot Smoothing

- Too much content. Maybe skip futures and just stick with foreach. Or skip some
  implementation parts of the running mean smoother, for instance.

## Lecture 6: Monte Carlo Simulation

- Remove or simplify variance estimator for the normalized importance sampling
  estimator. Or at least remove the code for it.

## Lecture 7: Optimization

- Too much material! Consider making Poisson example simpler.
- Or maybe move likelihood optimization to lecture 9 instead?
- Discuss compositions of convex functions, or at least motivate why we take log
  of likelihood
- Maybe move reading about likelihood optimization to next lecture

## Lecture 8: Debugging and Likelihood Optimization

- Make it easier for them to debug: put required functions and initialization of
  data in a script.

## Lecture 9: The EM Algorithm

- The function that's called the E step for the moth problem is not actually the
  E step, but rather just the expected counts of genotypes.
- People are confused by the notation where expected value is taken over
  $\theta'$. Maybe use Wikipedia notation instead, which is
  $\theta \sim p(\cdot
| X, \theta')$. Or just say that that is what's meant.
- Maybe just avoid the very general notation for the likelihood, involving the
  measure-theoretic stuff and use the unobserved/latent variable assumption
  instead.

## Lecture 10: EM Examples

- First exercise is maybe too difficult. Help them more somehow.
