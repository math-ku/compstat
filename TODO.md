---
title: Course Improvements
format: html
---

## General

- Harmonize notation with book
- Harmonize indicator notation
- Reconsider reading instructions; maybe not aligned properly.
- Start each lecture with a recap of the previous lecture.
- End each lecture with a summary of what was covered and a preview of the next
  lecture.
- Talk about computational complexity, maybe in first lecture (since it's
  central).
- Talk about exponential tilting for rejection and importance sampling.
- Overall time is skewed towards the optimization topic. Maybe cut some material
  and add another lecture on kernel density estimation or MCMC.

## Long-term

- Write lecture notes about optimization

### Interesting Topics that Could Be Covered

- Autodifferentiation
- GPU computing
- High-performance computing clusters

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

- Discuss compositions of convex functions, or at least motivate why we take log
  of likelihood (not sure)
- Maybe talk about strong convexity here.
- Maybe introduce overfitting and early stopping here instead of later for SGD

## Lecture 8: Debugging and Likelihood Optimization

- Make it easier for them to debug: put required functions and initialization of
  data in one script.

## Lecture 9: Likelihood Optimization and the EM algorithm

- Make it easier for them to debug: put required functions and initialization of
  data in one script.
- Make connection between EM algorithm and Gradient Descent and Newton's method
  clearer.

## Lecture 10: The EM Algorithm continued

- Drop the peppered moths example. It is too complicated. Use the Gaussian
  mixture example instead.
- Too much material. But if we remove the peppered moths example, it should be
  fine.
- Consider showing only two ways to derive the Fisher information from the
  complete data information, not all three.

## Lecture 11: Stochastic Gradient Descent

- Talk about strictly convex.

## Lecture 12: Rcpp

- Explain more clearly how it works in practice.
- Explain how compiling works and how errors look.
- Show practically during lecture how to write and compile.

## Lecture 13: SGD continued

- Add some part about variance reduction, like SVRG
- Show examples of how AdaGrad and RMSProp works

## Lecture 14: Wrap up and R packages

- The material is too extensive. Maybe scrap the exercises.
- Expand C++ example with actual task for them to do.
- Add instructions to re-install, document etc when they do things.
- Mention problem with rdb corruption that seems to happen.
- Maybe skip documentation part?
