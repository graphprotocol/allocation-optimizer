# Copyright 2022-, The Graph Foundation
# SPDX-License-Identifier: MIT

"""
    groupunique(x::AbstractVector)

Find the indices of each unique value in `x`

```julia
julia> using AllocationOpt
julia> x = [1, 2, 1, 3, 2, 3]
julia> AllocationOpt.groupunique(x)
Dict{Vector{Int64}, Vector{Int64}} with 3 entries:
  [3] => [4, 6]
  [1] => [1, 3]
  [2] => [2, 5]
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
julia> profitmatrix = [[2.5 5.0]; [2.5 1.0]]
julia> AllocationOpt.bestprofitpernz.(values(ixs), Ref(profitmatrix))
2-element Vector{NamedTuple{(:profit, :index), Tuple{Float64, Int64}}}:
 (profit = 5.0, index = 1)
 (profit = 6.0, index = 2)
```
"""
function bestprofitpernz(
    ixs::AbstractVector{T}, p::AbstractMatrix{S}
) where {T<:Integer,S<:Real}
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
        (; :profit => 5.0, :index => 2),
        (; :profit => 6.0, :index => 1)
    ]
julia> popts = AllocationOpt.sortprofits!(popts)
2-element Vector{NamedTuple{(:profit, :index), Tuple{Float64, Int64}}}:
 (profit = 6.0, index = 1)
 (profit = 5.0, index = 2)
```
"""
function sortprofits!(popts::AbstractVector{N}) where {N<:NamedTuple}
    return sort!(popts; by=x -> x[:profit], rev=true)
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
FlexTable with 3 columns and 2 rows:
     ipfshash  amount  profit
   ┌─────────────────────────
 1 │ Qma       2.5     3.0
 2 │ Qmb       2.5     3.0
```
"""
function reportingtable(
    s::FlexTable, xs::AbstractMatrix{T}, ps::AbstractMatrix{T}, i::Integer
) where {T<:Real}
    # Associate ipfs with allocation and profit vectors
    t = flextable((; :ipfshash => s.ipfsHash, :amount => xs[:, i], :profit => ps[:, i]))

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
julia> AllocationOpt.strategydict.(popts, Ref(xs), Ref(nonzeros), Ref(fs), Ref(profits))
2-element Vector{Dict{String, Any}}:
 Dict("num_allocations" => 2, "profit" => 6.0, "allocations" => Dict{String, Any}[Dict("allocationAmount" => "2.5", "profit" => 3.0, "deploymentID" => "Qma"), Dict("allocationAmount" => "2.5", "profit" => 3.0, "deploymentID" => "Qmb")])
 Dict("num_allocations" => 1, "profit" => 5.0, "allocations" => Dict{String, Any}[Dict("allocationAmount" => "5", "profit" => 5.0, "deploymentID" => "Qma")])
```
"""
function strategydict(
    p::NamedTuple,
    xs::AbstractMatrix{T},
    nonzeros::AbstractVector{I},
    fs::FlexTable,
    profitmatrix::AbstractMatrix{T},
) where {T<:Real,I<:Integer}
    i = p[:index]

    ft = reportingtable(fs, xs, profitmatrix, i)

    nnz = nonzeros[i]
    sp = p[:profit]
    allocations = map(ft) do r
        return Dict(
            "deploymentID" => r.ipfshash,
            "allocationAmount" => format(r.amount),
            "profit" => r.profit,
        )
    end

    # Construct dictionary
    strategy = Dict("num_allocations" => nnz, "profit" => sp, "allocations" => allocations)
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
    unallocate_action(::Val{:none}, a, t, config)

Do nothing.

```julia
julia> using AllocationOpt
julia> a = flextable([
            Dict("subgraphDeployment.ipfsHash" => "Qma", "id" => "0xa")
        ])
julia> t = flextable([
            Dict("amount" => "1", "profit" => "0", "ipfshash" => "Qma"),
            Dict("amount" => "2", "profit" => "0", "ipfshash" => "Qmb"),
        ])
julia> AllocationOpt.unallocate_action(Val(:none), a, t, Dict())
```
"""
unallocate_action(::Val{:none}, a, t, config) = nothing

"""
    reallocate_action(::Val{:none}, a, t, config)

Do nothing.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> a = flextable([
            Dict("subgraphDeployment.ipfsHash" => "Qma", "id" => "0xa")
        ])
julia> t = flextable([
            Dict("amount" => "1", "profit" => "0", "ipfshash" => "Qma"),
            Dict("amount" => "2", "profit" => "0", "ipfshash" => "Qmb"),
        ])
julia> AllocationOpt.reallocate_action(Val(:none), a, t, Dict())
"""
reallocate_action(::Val{:none}, a, t, config) = nothing

"""
    allocate_action(::Val{:none}, a, t, config)

Do nothing.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> a = flextable([
            Dict("subgraphDeployment.ipfsHash" => "Qma", "id" => "0xa")
        ])
julia> t = flextable([
            Dict("amount" => "1", "profit" => "0", "ipfshash" => "Qma"),
            Dict("amount" => "2", "profit" => "0", "ipfshash" => "Qmb"),
        ])
julia> AllocationOpt.allocate_action(Val(:none), a, t, Dict())
```
"""
allocate_action(::Val{:none}, a, t, config) = nothing

"""
    unallocate_action(::Val{:rules}, a::FlexTable, t::FlexTable, config::AbstractDict)

Print a rule that stops old allocations that the optimiser has not chosen and that aren't
frozen.

```julia
julia> using AllocationOpt
julia> a = flextable([
            Dict("subgraphDeployment.ipfsHash" => "Qma", "id" => "0xa")
        ])
julia> t = flextable([
            Dict("amount" => "2", "profit" => "0", "ipfshash" => "Qmb"),
        ])
julia> AllocationOpt.unallocate_action(Val(:rules), a, t, Dict("frozenlist" => []))
graph indexer rules stop Qma
1-element Vector{String}:
 "\e[0mgraph indexer rules stop Qma"
```
"""
function unallocate_action(::Val{:rules}, a::FlexTable, t::FlexTable, config::AbstractDict)
    frozenlist = config["frozenlist"]
    existingipfs = ipfshash(Val(:allocation), a)
    proposedipfs = t.ipfshash
    ipfses = closeipfs(existingipfs, proposedipfs, frozenlist)
    actions::Vector{String} = map(ipfs -> "\e[0mgraph indexer rules stop $(ipfs)", ipfses)
    println.(actions)
    return actions
end

"""
    reallocate_action(::Val{:rules}, a::FlexTable, t::FlexTable, config::AbstractDict)

Print a rule that reallocates the old allocation with a new allocation amount

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> a = flextable([
            Dict("subgraphDeployment.ipfsHash" => "Qma", "id" => "0xa")
        ])
julia> t = flextable([
    Dict("amount" => "1", "profit" => "0", "ipfshash" => "Qma"),
    Dict("amount" => "2", "profit" => "0", "ipfshash" => "Qmb"),
])
julia> AllocationOpt.reallocate_action(Val(:rules), a, t, Dict())
graph indexer rules stop Qma
Check allocation status being closed before submitting: graph indexer rules set Qma decisionBasis always allocationAmount 1
1-element Vector{String}:
 "\e[0mgraph indexer rules stop Qm" ⋯ 122 bytes ⋯ "asis always allocationAmount 1"
```
"""
function reallocate_action(::Val{:rules}, a::FlexTable, t::FlexTable, config::AbstractDict)
    existingipfs = ipfshash(Val(:allocation), a)
    # Filter table to only include subgraphs that are already allocated
    ti = SAC.filterview(r -> r.ipfshash ∈ existingipfs, t)
    ipfses = ti.ipfshash
    amounts = ti.amount

    actions::Vector{String} = map(
        (ipfs, amount) ->
            "\e[0mgraph indexer rules stop $(ipfs)\n\e[1m\e[38;2;255;0;0;249mCheck allocation status being closed before submitting: \e[0mgraph indexer rules set $(ipfs) decisionBasis always allocationAmount $(format(amount))",
        ipfses,
        amounts,
    )
    println.(actions)
    return actions
end

"""
    allocate_action(::Val{:rules}, a::FlexTable, t::FlexTable, config::AbstractDict)

Print the rules that allocates to new subgraphs.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> a = flextable([
            Dict("subgraphDeployment.ipfsHash" => "Qma", "id" => "0xa")
        ])
julia> t = flextable([
            Dict("amount" => "1", "profit" => "0", "ipfshash" => "Qma"),
            Dict("amount" => "2", "profit" => "0", "ipfshash" => "Qmb"),
        ])
julia> AllocationOpt.allocate_action(Val(:rules), a, t, Dict())
graph indexer rules set Qmb decisionBasis always allocationAmount 2
1-element Vector{String}:
 "\e[0mgraph indexer rules set Qmb decisionBasis always allocationAmount 2"
"""
function allocate_action(::Val{:rules}, a::FlexTable, t::FlexTable, config::AbstractDict)
    existingipfs = ipfshash(Val(:allocation), a)
    # Filter table to only include subgraphs that are not already allocated
    ts = SAC.filterview(r -> r.ipfshash ∉ existingipfs, t)
    ipfses = ts.ipfshash
    amounts = ts.amount

    actions::Vector{String} = map(
        (ipfs, amount) ->
            "\e[0mgraph indexer rules set $(ipfs) decisionBasis always allocationAmount $(format(amount))",
        ipfses,
        amounts,
    )
    println.(actions)
    return actions
end

"""
    closeipfs(existingipfs, proposedipfs, frozenlist)

Get the list of the ipfs hashes of allocations to close.

```julia
julia> using AllocationOpt
julia> AllocationOpt.closeipfs(["Qma"], ["Qmb"], String[])
1-element Vector{String}:
 "Qma"
```
"""
function closeipfs(existingipfs, proposedipfs, frozenlist)
    return setdiff(setdiff(existingipfs, proposedipfs), frozenlist)
end

@enum ActionStatus begin
    queued
    approved
    pending
    success
    failed
    canceled
end

@enum ActionType begin
    allocate
    unallocate
    reallocate
    collect
end

"""
    unallocate_action(::Val{:actionqueue}, a::FlexTable, t::FlexTable, config::AbstractDict)

Create and push the unallocate actions to the action queue.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> a = flextable([
            Dict("subgraphDeployment.ipfsHash" => "Qma", "id" => "0xa")
        ])
julia> t = flextable([
            Dict("amount" => "2", "profit" => "0", "ipfshash" => "Qmb"),
        ])
julia> config = Dict(
    "frozenlist" => [],
    "indexer_url" => "http://localhost:18000"
)
julia> TheGraphData.client!(config["indexer_url"])
julia> AllocationOpt.unallocate_action(Val(:actionqueue), a, t, config)
1-element Vector{Dict{String, Any}}:
 Dict("priority" => 0, "status" => AllocationOpt.queued, "allocationID" => "0xa", "source" => "AllocationOpt", "reason" => "AllocationOpt", "type" => AllocationOpt.unallocate, "deploymentID" => "Qma", "protocolNetwork" => "mainnet")
"""
function unallocate_action(
    ::Val{:actionqueue}, a::FlexTable, t::FlexTable, config::AbstractDict
)
    toallocatelist = config["frozenlist"] ∪ t.ipfshash
    ft = SAC.filterview(r -> ipfshash(Val(:allocation), r) ∉ toallocatelist, a)

    actions::Vector{Dict{String,Any}} = map(
        r -> Dict(
            "status" => queued,
            "type" => unallocate,
            "allocationID" => id(Val(:allocation), r),
            "deploymentID" => ipfshash(Val(:allocation), r),
            "source" => "AllocationOpt",
            "reason" => "AllocationOpt",
            "priority" => 0,
            "protocolNetwork" => config["protocol_network"],
        ),
        ft,
    )

    # Send graphql mutation to action queue
    @mock(mutate("queueActions", Dict("actions" => actions); direct_write=true))

    return actions
end

"""
    reallocate_action(::Val{:actionqueue}, a::FlexTable, t::FlexTable, config::AbstractDict)

Create and push reallocate actions to the action queue.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> a = flextable([
            Dict("subgraphDeployment.ipfsHash" => "Qma", "id" => "0xa")
        ])
julia> t = flextable([
    Dict("amount" => "1", "profit" => "0", "ipfshash" => "Qma"),
    Dict("amount" => "2", "profit" => "0", "ipfshash" => "Qmb"),
])
julia> config = Dict("indexer_url" => "http://localhost:18000")
julia> TheGraphData.client!(config["indexer_url"])
julia> AllocationOpt.reallocate_action(Val(:actionqueue), a, t, config)
1-element Vector{Dict{String, Any}}:
 Dict("amount" => "1", "priority" => 0, "status" => AllocationOpt.queued, "allocationID" => "0xa", "source" => "AllocationOpt", "reason" => "Expected profit: 0", "type" => AllocationOpt.reallocate, "deploymentID" => "Qma", "protocolNetwork" => "mainnet")
```
"""
function reallocate_action(
    ::Val{:actionqueue}, a::FlexTable, t::FlexTable, config::AbstractDict
)
    ti = SAC.innerjoin(
        getproperty(:ipfshash), getproperty(Symbol("subgraphDeployment.ipfsHash")), t, a
    )

    actions::Vector{Dict{String,Any}} = map(
        r -> Dict(
            "status" => queued,
            "type" => reallocate,
            "allocationID" => id(Val(:allocation), r),
            "deploymentID" => ipfshash(Val(:allocation), r),
            "amount" => format(r.amount),
            "source" => "AllocationOpt",
            "reason" => "Expected profit: $(format(r.profit))",
            "priority" => 0,
            "protocolNetwork" => config["protocol_network"],
        ),
        ti,
    )

    # Send graphql mutation to action queue
    @mock(mutate("queueActions", Dict("actions" => actions); direct_write=true))

    return actions
end

"""
    allocate_action(::Val{:actionqueue}, a::FlexTable, t::FlexTable, config::AbstractDict)

Create and push allocate actions to the action queue.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> a = flextable([
            Dict("subgraphDeployment.ipfsHash" => "Qma", "id" => "0xa")
        ])
julia> t = flextable([
    Dict("amount" => "1", "profit" => "0", "ipfshash" => "Qma"),
    Dict("amount" => "2", "profit" => "0", "ipfshash" => "Qmb"),
])
julia> config = Dict(
    "indexer_url" => "http://localhost:18000"
)
julia> TheGraphData.client!(config["indexer_url"])
julia> AllocationOpt.allocate_action(Val(:actionqueue), a, t, config)
1-element Vector{Dict{String, Any}}:
 Dict("amount" => "2", "priority" => 0, "status" => AllocationOpt.queued, "source" => "AllocationOpt", "reason" => "Expected profit: 0", "type" => AllocationOpt.allocate, "deploymentID" => "Qmb", "protocolNetwork" => "mainnet")
```
"""
function allocate_action(
    ::Val{:actionqueue}, a::FlexTable, t::FlexTable, config::AbstractDict
)
    existingipfs = ipfshash(Val(:allocation), a)
    # Filter table to only include subgraphs that are not already allocated
    ts = SAC.filterview(r -> r.ipfshash ∉ existingipfs, t)

    actions::Vector{Dict{String,Any}} = map(
        r -> Dict(
            "status" => queued,
            "type" => allocate,
            "deploymentID" => r.ipfshash,
            "amount" => format(r.amount),
            "source" => "AllocationOpt",
            "reason" => "Expected profit: $(format(r.profit))",
            "priority" => 0,
            "protocolNetwork" => config["protocol_network"],
        ),
        ts,
    )

    # Send graphql mutation to action queue
    @mock(mutate("queueActions", Dict("actions" => actions); direct_write=true))

    return actions
end

"""
    execute(
        a::FlexTable,
        ix::Integer,
        s::FlexTable,
        xs::AbstractMatrix{T},
        ps::AbstractMatrix{T},
        config::AbstractDict
    ) where {T<:Real}

Execute the actions picked by the optimiser.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> a = flextable([
            Dict("subgraphDeployment.ipfsHash" => "Qma", "id" => "0xa")
        ])
julia> xs = [[2.5 5.0]; [2.5 0.0]]
julia> ps = [[3.0 5.0]; [3.0 0.0]]
julia> s = flextable([
            Dict("stakedTokens" => "1", "signalledTokens" => "0", "ipfsHash" => "Qma"),
            Dict("stakedTokens" => "2", "signalledTokens" => "0", "ipfsHash" => "Qmb"),
        ])
julia> config = Dict("execution_mode" => "none")
julia> ix = 1
julia> AllocationOpt.execute(a, ix, s, xs, ps, config)
```
"""
function execute(
    a::FlexTable,
    ix::Integer,
    s::FlexTable,
    xs::AbstractMatrix{T},
    ps::AbstractMatrix{T},
    config::AbstractDict,
) where {T<:Real}
    # Construct t
    t = reportingtable(s, xs, ps, ix)

    mode = Val(Symbol(config["execution_mode"]))

    indexerurlclient(mode, config)
    _ = unallocate_action(mode, a, t, config)
    _ = reallocate_action(mode, a, t, config)
    _ = allocate_action(mode, a, t, config)

    return nothing
end

indexerurlclient(::Val{:actionqueue}, config::AbstractDict) = client!(config["indexer_url"])
indexerurlclient(::Any, config::AbstractDict) = nothing
