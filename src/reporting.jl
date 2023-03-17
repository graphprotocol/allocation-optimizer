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
function groupunique(x::AbstractVector)
    ixs = SAC.groupfind(unique, x)
    ixs = Dict(keys(ixs) .=> values(ixs))
    return ixs
end

"""
    bestprofitpernz(ixs::AbstractVector{Integer}, profitmatrix::AbstractMatrix{Real})

Compute the best profit amongst the given `ixs` given profit matrix `p`

```julia
julia> using AllocationOpt
julia> ixs = Dict([1] => [1], [2] => [2])
julia> profitmatrix = [[2.5 5.0]; [2.5, 1.0]]
julia> AllocationOpt.bestprofitpernz.(values(ixs), Ref(profitmatrix))
```
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

```julia
julia> using AllocationOpt
julia> popts = [
        (; :profit => 6.0, :index => 1),
        (; :profit => 5.0, :index => 2)
    ]
julia> popts = sortprofits!(popts)
```
"""
function sortprofits!(popts::AbstractVector{N}) where {N<:NamedTuple}
    sort!(popts; by=x -> x[:profit], rev=true)
end

"""
    reportingtable(
        s::FlexTable, xs::AbstractMatrix{Real}, ps::AbstractMatrix{Real}, i::Integer
    )

Construct a table for the strategy mapping the ipfshash, allocation amount, and profit

```julia
julia> using AllocationOpt
julia> s = flextable([
        Dict("stakedTokens" => "1", "signalledTokens" => "2", "ipfsHash" => "Qma"),
        Dict("stakedTokens" => "2", "signalledTokens" => "1", "ipfsHash" => "Qmb"),
    ])
julia> xs = [[2.5 5.0]; [2.5 0.0]]
julia> ps = [[3.0 5.0]; [3.0 0.0]]
julia> i = 1
julia> AllocationOpt.reportingtable(s, xs, ps, i)
```
"""
function reportingtable(
    s::FlexTable, xs::AbstractMatrix{T}, ps::AbstractMatrix{T}, i::Integer
) where {T<:Real}
    # Associate ipfs with allocation and profit vectors
    t = flextable(
        (; :ipfshash => s.ipfsHash, :amount => xs[:, i], :profit => ps[:, i])
    )

    # Filter table to only include nonzeros
    ft = SAC.filterview(r -> r.amount > 0, t)

    return ft
end

"""
    strategydict(
        p::NamedTuple,
        xs::AbstractMatrix{Real},
        nonzeros::AbstractVector{Integer},
        fs::FlexTable,
        profitmatrix::AbstractMatrix{Real}
    )

For a profit, index pair `p`, generate the nested dictionary representing the data to
convert to a JSON string. `xs` is the allocation strategy matrix, `nonzeros` are the number
of nonzeros in each allocation strategy, `fs` is a table containing subgraph ipfshashes,
and the `profitmatrix` is a matrix containing profit for each allocation in `xs`

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> popts = [
        (; :profit => 6.0, :index => 1),
        (; :profit => 5.0, :index => 2)
    ]
julia> xs = [[2.5 5.0]; [2.5 0.0]]
julia> profits = [[3.0 5.0]; [3.0 0.0]]
julia> nonzeros = [2, 1]
julia> fs = flextable([
        Dict("stakedTokens" => "1", "signalledTokens" => "0", "ipfsHash" => "Qma"),
        Dict("stakedTokens" => "2", "signalledTokens" => "0", "ipfsHash" => "Qmb"),
    ])
julia> AllocationOpt.strategydict(popts, Ref(xs), Ref(nonzeros), Ref(fs), Ref(profits))
```
"""
function strategydict(
    p::NamedTuple,
    xs::AbstractMatrix{T},
    nonzeros::AbstractVector{I},
    fs::FlexTable,
    profitmatrix::AbstractMatrix{T}
) where {T<:Real, I<:Integer}
    i = p[:index]

    ft = reportingtable(fs, xs, profitmatrix, i)

    nnz = nonzeros[i]
    sp = p[:profit]
    allocations = map(ft) do r
        return Dict(
                "deploymentID" => r.ipfshash,
                "allocationAmount" => format(r.amount),
                "profit" => r.profit
        )
    end

    # Construct dictionary
    strategy = Dict(
        "num_allocations" => nnz,
        "profit" => sp,
        "allocations" => allocations,
    )
    return strategy
end

"""
    function writejson(results::AbstractString, config::AbstractDict)

Write the optimized results to the `writedir` specified in the `config`.

```julia
julia> Using AllocationOpt
julia> results = "{\"strategies\":[{\"num_allocations\":2,\"profit\":6.0,\"allocations\":[{\"allocationAmount\":2.5,\"profit\":3.0,\"deploymentID\":\"Qma\"},{\"allocationAmount\":2.5,\"profit\":3.0,\"deploymentID\":\"Qmb\"}]},{\"num_allocations\":1,\"profit\":5.0,\"allocations\":[{\"allocationAmount\":5.0,\"profit\":5.0,\"deploymentID\":\"Qma\"}]}]}"
julia> config = Dict{"writedir" => "."}
julia> AllocationOpt.writejson(results, config)
```
"""
function writejson(results::AbstractString, config::AbstractDict)
    p = joinpath(config["writedir"], "report.json")
    f = open(abspath(p), "w")
    @mock(JSON.print(f, JSON.parse(results)))
    close(f)
    return p
end

"""
    unallocate(::Val{:none}, proposedipfs, existingipfs, config)

Do nothing.

```julia
julia> using AllocationOpt
julia> AllocationOpt.unallocate(Val{:none}, ["Qma"], ["Qmb"], Dict())
```
"""
unallocate(::Val{:none}, proposedipfs, existingipfs, config) = nothing


"""
    reallocate(::Val{:none}, existingipfs, t, config)

Do nothing.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> t = flextable([
    Dict("stakedTokens" => "1", "signalledTokens" => "0", "ipfsHash" => "Qma"),
    Dict("stakedTokens" => "2", "signalledTokens" => "0", "ipfsHash" => "Qmb"),
])
julia> AllocationOpt.reallocate(Val{:none}, ["Qma"], t, Dict())
"""
reallocate(::Val{:none}, existingipfs, t, config) = nothing

"""
    allocate(::Val{:none}, existingipfs, t, config)

Do nothing.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> existingipfs = ["Qma"]
julia> t = flextable([
    Dict("stakedTokens" => "1", "signalledTokens" => "0", "ipfsHash" => "Qma"),
    Dict("stakedTokens" => "2", "signalledTokens" => "0", "ipfsHash" => "Qmb"),
])
julia> AllocationOpt.allocate(Val{:none}, existingipfs, t, Dict())
```
"""
allocate(::Val{:none}, existingipfs, t, config) = nothing
