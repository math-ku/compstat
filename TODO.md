# Improvements for Course

## General

- Turn all slides into beamer presentations instead
- Reconsider best way to have exercises during lectures. It should either be present in each lecture.
  Maybe something very simple is enough? Just to keep students engaged and active.
- Maybe harmonize notation with book?
- Maybe introduce R packages?
- Get rid of S3 object-oriented design?
- Generally reconsider reading instructions; maybe not aligned properly.

### Interesting Topics that Could Be Covered

- Gibbs sampling
- Autodifferentiation
- Two-dimensional kernel density estimation
- Stan?
- Iteratively reweighted least-squares

## Lecture 8: Optimization

- Too much material! Consider making Poisson example simpler.
- Or maybe move likelihood optimization to lecture 9 instead?
- Discuss compositions of convex functions, or at least motivate why we take log of likelihood
- Maybe move reading about likelihood optimization to next lecture

## Lecture 9: Debugging and Likelihood Optimization

- Move debugging to an earlier lecture.
- Make it easier for them to debug: put required functions and initialization of data in a script.

## Lecture 10: The EM Algorithm

- The function that's called the E step for the moth problem
  is not actually the E step, but rather just the expected
  counts of genotypes.
- People are confused by the notation where expected value is taken over $\theta'$. Maybe use
  Wikipedia notation instead, which is $\theta \sim p(\cdot | X, \theta')$. Or just
  say that that is what's meant.
- Maybe just avoid the very general notation for the likelihood, involving
  the measure-theoretic stuff and use the unobserved/latent variable
  assumption instead.

## Lecture 11: EM Examples

- First exercise is maybe too difficult. Help them more somehow.
