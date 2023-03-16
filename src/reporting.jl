# Copyright 2022-, The Graph Foundation
# SPDX-License-Identifier: MIT

"""
    groupunique(x::AbstractVector)

Find the indices of each unique value in `x`

```julia
julia> using AllocationOpt
julia> x = [1, 2, 1, 3, 2, 3]
julia> AllocationOpt.groupunique(x)
```
"""
groupunique(x::AbstractVector) = SAC.groupfind(unique, x)

"""
    bestprofitpernz(ixs::AbstractVector{Integer}, profitmatrix::AbstractMatrix{Real})

Compute the best profit amongst the given `ixs` given profit matrix `p`

```julia
julia> using AllocationOpt
julia> ixs = Dict([1] => [1], [2] => [2])
julia> profitmatrix = [[2.5 5.0]; [2.5, 1.0]]
julia> popts = AllocationOpt.bestprofitpernz.(values(ixs), Ref(profitmatrix))
"""
function bestprofitpernz(
    ixs::AbstractVector{T},
    p::AbstractMatrix{S}
) where {T<:Integer, S<:Real}
    # Sum the ixth profit vector and find the max over all of them
    v, i = findmax(map(ix -> p[:, ix] |> sum, ixs))
    return (; :profit => v, :index => ixs[i])
end

"""
    sortprofits!(NamedTuple{Tuple{Float64, Int64}})
Sort the nonzero best profits from highest to lowest


[(profit = 5.0, index = 1), (profit = 6.0, index = 2)]
"""
function sortprofits!(popts::AbstractVector{N}) where {N<:NamedTuple}
    sort!(popts; by=x -> x[:profit], rev=true)
end
