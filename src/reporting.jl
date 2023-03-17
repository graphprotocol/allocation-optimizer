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
    reallocate(::Val{:none}, a, t, config)

Do nothing.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia > a = flextable([
            Dict("subgraphDeployment.ipfsHash" => "Qma", "id" => "0xa")
        ])
julia> t = flextable([
            Dict("amount" => "1", "profit" => "0", "ipfshash" => "Qma"),
            Dict("amount" => "2", "profit" => "0", "ipfshash" => "Qmb"),
        ])
julia> AllocationOpt.reallocate(Val{:none}, a, t, Dict())
"""
reallocate(::Val{:none}, a, t, config) = nothing

"""
    allocate(::Val{:none}, existingipfs, t, config)

Do nothing.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia > a = flextable([
            Dict("subgraphDeployment.ipfsHash" => "Qma", "id" => "0xa")
        ])
julia> t = flextable([
            Dict("amount" => "1", "profit" => "0", "ipfshash" => "Qma"),
            Dict("amount" => "2", "profit" => "0", "ipfshash" => "Qmb"),
        ])
julia> AllocationOpt.allocate(Val{:none}, a, t, Dict())
```
"""
allocate(::Val{:none}, a, t, config) = nothing

"""
    unallocate(
        ::Val{:rules},
        proposedipfs::AbstractVector{S},
        existingipfs::AbstractVector{S},
        config::AbstractDict,
    ) where {S<:AbstractString}

Print a rule that stops old allocations that the optimiser has not chosen and that aren't
frozen.

```julia
julia> using AllocationOpt
julia> AllocationOpt.unallocate(Val{:rules}, ["Qma"], ["Qmb"], Dict("frozenlist" => []))
```
"""
function unallocate(
    ::Val{:rules},
    proposedipfs::AbstractVector{S},
    existingipfs::AbstractVector{S},
    config::AbstractDict,
) where {S<:AbstractString}
    frozenlist = config["frozenlist"]
    ipfses = closeipfs(existingipfs, proposedipfs, frozenlist)
    actions::Vector{String} = map(ipfs -> "\e[0mgraph indexer rules stop $(ipfs)", ipfses)
    println.(actions)
    return actions
end

"""
    reallocate(
        ::Val{:rules},
        a::FlexTable,
        t::FlexTable,
        config::AbstractDict,
    ) where {S<:AbstractString}

Print a rule that reallocates the old allocation with a new allocation amount

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia > a = flextable([
            Dict("subgraphDeployment.ipfsHash" => "Qma", "id" => "0xa")
        ])
julia> t = flextable([
    Dict("amount" => "1", "profit" => "0", "ipfshash" => "Qma"),
    Dict("amount" => "2", "profit" => "0", "ipfshash" => "Qmb"),
])
julia> AllocationOpt.reallocate(Val(:rules), a, t, Dict())
```
"""
function reallocate(
    ::Val{:rules},
    a::FlexTable,
    t::FlexTable,
    config::AbstractDict,
)
    existingipfs = ipfshash(Val(:allocation), a)
    # Filter table to only include subgraphs that are already allocated
    ti = SAC.filterview(r -> r.ipfshash ∈ existingipfs, t)
    ipfses = ti.ipfshash
    amounts = ti.amount

    actions::Vector{String} = map(
        (ipfs, amount) ->
            "\e[0mgraph indexer rules stop $(ipfs)\n\e[1m\e[38;2;255;0;0;249mCheck allocation status being closed before submitting: \e[0mgraph indexer rules set $(ipfs) decisionBasis always allocationAmount $(format(amount))",
        ipfses,
        amounts
    )
    println(actions)
    return actions
end

"""
    allocate(
        ::Val{:rules},
        a::FlexTable,
        t::FlexTable,
        config::AbstractDict,
    ) where {S<:AbstractString}

Print the rules that allocates to new subgraphs.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia > a = flextable([
            Dict("subgraphDeployment.ipfsHash" => "Qma", "id" => "0xa")
        ])
julia> t = flextable([
            Dict("amount" => "1", "profit" => "0", "ipfshash" => "Qma"),
            Dict("amount" => "2", "profit" => "0", "ipfshash" => "Qmb"),
        ])
julia> AllocationOpt.allocate(Val{:rules}, a, t, Dict())
"""
function allocate(
    ::Val{:rules},
    a::FlexTable,
    t::FlexTable,
    config::AbstractDict,
)
    existingipfs = ipfshash(Val(:allocation), a)
    # Filter table to only include subgraphs that are not already allocated
    ts = SAC.filterview(r -> r.ipfshash ∉ existingipfs, t)
    ipfses = ts.ipfshash
    amounts = ts.amount

    actions::Vector{String} = map(
        (ipfs, amount) ->
            "\e[0mgraph indexer rules set $(ipfs) decisionBasis always allocationAmount $(format(amount))",
        ipfses,
        amounts
    )
    println(actions)
    return actions
end

"""
    closeipfs(existingipfs, proposedipfs, frozenlist)

Get the list of the ipfs hashes of allocations to close.

```julia
julia> using AllocationOpt
julia> AllocationOptcloseipfs(["Qma"], ["Qmb"], String[])
```
"""
function closeipfs(existingipfs, proposedipfs, frozenlist)
    setdiff(setdiff(existingipfs, proposedipfs), frozenlist)
end
