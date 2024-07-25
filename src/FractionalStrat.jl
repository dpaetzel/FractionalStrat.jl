module FractionalStrat

using Random
using StatsBase

export fractionalstrat

# Create “temporary partitions”, i.e. create `q` roughly equally-sized
# groups of successive indices of y.
function tempparts(idx_sorted, q)
    N = length(idx_sorted)
    return [idx_sorted[floor(Int, (i - 1) * N / q + 1):floor(Int, i * N / q)] for i = 1:q]
end

function assignonce!(rng, Ω_indices, π_indices, proportions)
    # Go over all “temporary partitions”.
    for j in axes(Ω_indices, 1)
        # Length of the current “temporary partition”.
        Qj = length(Ω_indices[j])
        # For each subset that we're trying to build, sample from the partition.
        for i in axes(proportions, 1)
            # Number of samples to put into subset `i`.
            nsamples = floor(Int, proportions[i] * Qj)
            # Sample `nsamples` indices from the current temporary partition.
            idxs_selected = sample(rng, axes(Ω_indices[j], 1), nsamples; replace = false)
            # Put the elements corresponding to the indices into subset `i`.
            append!(π_indices[i], Ω_indices[j][idxs_selected])
            # Remove the selected elements from the current temporary partition.
            # We sort because that's required by `deletat!`.
            deleteat!(Ω_indices[j], sort(idxs_selected))
        end
    end
end

"""
    fractionalstrat(y, proportions, precision)

Partition the indices of `y` using the fractional stratification algorithm as
explained e.g. in [this blog
post](https://scottclowe.com/2016-03-19-stratified-regression-partitions/).


# Arguments

- `y::T`: The vector whose indices to split.
- `proportions::AbstractVector{<:Number}`: The proportions to split the indices
  into. Have to sum to 1 and be positive.
- `precision::Int`: Number of bins to create. From each bin, we sample
  approximately according to the proportions. The lower the smaller the patterns
  in `y` that are split.
"""
function fractionalstrat(
    rng::AbstractRNG,
    y::AbstractVector{T},
    proportions::Vector{Float64},
    precision::Int,
) where {T<:Number}
    N = length(y)
    q = precision
    P = length(proportions)
    proportions_orig = copy(proportions)

    if sum(proportions) != 1.0
        throw(ArgumentError("Proportions must sum to 1"))
    end

    # Sort data based on y and get the indices. We have to collect because Julia
    # tries to be smart and creates a `UnitRange` object in some cases otherwise.
    idx_sorted = collect(sortperm(y))
    # sorted_data = y[idx_sorted]

    # Create “temporary partitions”, i.e. create `q` roughly equally-sized
    # groups of successive indices of y.
    Ω_indices = tempparts(idx_sorted, q)
    @assert sum(length.(Ω_indices)) == N
    # I'm not 100% sure whether these assertions always hold.
    @assert minimum(length.(Ω_indices)) >= floor(N / q)
    @assert maximum(length.(Ω_indices)) == ceil(N / q)

    if any(sum(floor.(proportions' .* length.(Ω_indices)); dims = 1) .== 0)
        # TODO Pretty sure that we can formally derive the lower bound and put
        # it into the docstring
        throw(
            ArgumentError(
                "Too little data for the given proportions and precision " *
                "(would yield empty subset)",
            ),
        )
    end

    # Initialize the subsets we're building.
    π_indices = [Int[] for _ = 1:P]

    assignonce!(rng, Ω_indices, π_indices, proportions)

    # Number of unallocated samples.
    R = sum(length.(Ω_indices))

    while R != 0
        if q == 1
            proportions = (proportions_orig .* N - length.(π_indices)) / R
            remainder = reduce(vcat, Ω_indices)
            # Sample for each of the remaining data points a partition to add it
            # to. Provide the proportions as weights.
            addtopartition =
                wsample(rng, axes(π_indices, 1), proportions, length(remainder))
            for i in axes(addtopartition, 1)
                append!(π_indices[addtopartition[i]], remainder[i])
            end
            # We set `R` to zero in this case because we assigned all the
            # remaining data points to partitions by now (without updating
            # `Ω_indices`).
            R = 0
            break
        end
        proportions = (proportions_orig .* N - length.(π_indices)) / R
        if !isapprox(sum(proportions), 1)
            throw(AssertionError("sum(proportions) == $(sum(proportions)) ≠ 1"))
        end
        @assert all(0 .<= proportions .<= 1)
        q = floor(q / 2)
        Ω_indices = tempparts(reduce(vcat, Ω_indices), q)

        assignonce!(rng, Ω_indices, π_indices, proportions)

        # Number of unallocated samples.
        R = sum(length.(Ω_indices))
    end

    @assert R == 0
    @assert sum(length.(π_indices)) == N
    π_indices_joint = reduce(vcat, π_indices)
    @assert sort(π_indices_joint) == axes(y, 1)

    return π_indices
end

fractionalstrat(
    y::AbstractVector{T},
    proportions::Vector{Float64},
    precision::Int,
) where {T<:Number} = fractionalstrat(Random.default_rng(), y, proportions, precision)

end
