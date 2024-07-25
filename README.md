# Fractional stratification for continuous targets in Julia


A library currently exposing a single function, `fractionalstrat`, which allows
to split data by fractional stratification. Fractional stratification attempts
to partition data `y` such that each block has approximately the same
distribution as `y`.


How does it work? In short, we first partition the *sorted* data using a
user-configured block size (can be used to configure how closely we want to
mimick the distribution of `y` in each split). We then sample according to the
split rates from each of the just-created blocks into the final split blocks.
Since this likely will not “use up” all the data points in the sorted blocks, we
then repeatedly adjust the split rates and sample into the split blocks further
until all data points are assigned to one of the splits. [This blog post by
Scott C.
Lowe](https://scottclowe.com/2016-03-19-stratified-regression-partitions/#fractional-stratification)
explains the algorithm quite well in a more formal way.


## Usage


See `scripts/example.jl`.

tl;dr

```
using Random
rng = Random.Xoshiro(42)
N = 50
X = rand(rng, N)
y = @. 3 * X + 1 + randn(rng) * 0.15

using FractionalStrat

idxs = fractionalstrat(y, [0.8, 0.2], 7)
Xtrain, ytrain = X[idxs[1]], y[idxs[1]]
Xtest, ytest = X[idxs[2]], y[idxs[2]]
```
