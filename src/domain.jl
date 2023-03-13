# Copyright 2022-, The Graph Foundation
# SPDX-License-Identifier: MIT

const ethtogrt = 1e18
const pinnedamount = 0.1

"""
    togrt(x::AbstractString)

Convert `x` to GRT.

!!! note
    This function is meant to be used with freshly queried data, so it operates on strings.

```julia
julia> using AllocationOpt
julia> AllocationOpt.togrt("1")
```
"""
togrt(x::AbstractString) = parse(Float64, x) / ethtogrt

"""
    ipfshash(::Val{:allocation}, x)

Get the ipfs hash of `x` when `x` is part of the allocation table.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> x = flextable([
    Dict(
        "subgraphDeployment.ipfsHash" => "Qma",
    ),
])
julia> AllocationOpt.ipfshash(Val(:allocation), x)
```
"""
ipfshash(::Val{:allocation}, x) = getproperty(x, Symbol("subgraphDeployment.ipfsHash"))

"""
    stake(::Val{:allocation}, x)

Get the allocated tokens for each allocation in `x`.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> x = flextable([
    Dict(
        "subgraphDeployment.ipfsHash" => "Qma",
        "allocatedTokens" => 1,
    ),
])
julia> AllocationOpt.stake(Val(:allocation), x)
```
"""
stake(::Val{:allocation}, x) = x.allocatedTokens

"""
    ipfshash(::Val{:subgraph}, x)

Get the ipfs hash of `x` when `x` is part of the allocation table.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> x = flextable([
    Dict(
        "ipfsHash" => "Qma",
    ),
])
julia> AllocationOpt.ipfshash(Val(:allocation), x)
```
"""
ipfshash(::Val{:subgraph}, x) = x.ipfsHash

"""
    stake(::Val{:subgraph}, x)

The tokens staked on the subgraphs in table `x`.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> x = flextable([
    Dict("stakedTokens" => 10,),
    Dict("stakedTokens" => 5,),
])
julia> AllocationOpt.stake(Val(:subgraph), x)
```
"""
stake(::Val{:subgraph}, x) = x.stakedTokens

"""
    signal(::Val{:subgraph}, x)

The tokens signalled on the subgraphs in table `x`.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> x = flextable([
    Dict("signalledTokens" => 10,),
    Dict("signalledTokens" => 5,),
])
julia> AllocationOpt.signal(Val(:subgraph), x)
```
"""
signal(::Val{:subgraph}, x) = x.signalledTokens

"""
    stake(::Val{:indexer}, x)

The tokens staked by the indexer in table `x`.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> x = flextable([
    Dict(
        "stakedTokens" => 10,
    ),
])
julia> AllocationOpt.stake(Val(:indexer), x)
```
"""
stake(::Val{:indexer}, x) = x.stakedTokens |> only

"""
    delegation(::Val{:indexer}, x)

The tokens delegated to the indexer in table `x`.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> x = flextable([
    Dict(
        "delegatedTokens" => 10,
    ),
])
julia> AllocationOpt.delegation(Val(:indexer), x)
```
"""
delegation(::Val{:indexer}, x) = x.delegatedTokens |> only

"""
    locked(::Val{:indexer}, x)

The locked tokens of the indexer in table `x`.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> x = flextable([
    Dict(
        "lockedTokens" => 10,
    ),
])
julia> AllocationOpt.locked(Val(:indexer), x)
```
"""
locked(::Val{:indexer}, x) = x.lockedTokens |> only

"""
    frozen(a::FlexTable, config::AbstractDict)

The frozen stake of the indexer with allocations `a`.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> a = flextable([
            Dict("subgraphDeployment.ipfsHash" => "Qma", "allocatedTokens" => 5),
            Dict("subgraphDeployment.ipfsHash" => "Qmb", "allocatedTokens" => 10),
       ])
julia> config = Dict("frozenlist" => ["Qma", "Qmb"])
julia> AllocationOpt.frozen(a, config)
```
"""
function frozen(a::FlexTable, config::AbstractDict)
    frozenallocs = SAC.filterview(r -> ipfshash(Val(:allocation), r) ∈ config["frozenlist"], a)
    return stake(Val(:allocation), frozenallocs) |> sum
end

"""
    pinned(config::AbstractDict)

The pinned stake of the indexer.

```julia
julia> using AllocationOpt
julia> config = Dict("pinnedlist" => ["Qma", "Qmb"])
julia> AllocationOpt.pinned(config)
```
"""
pinned(config::AbstractDict) = pinnedamount * length(config["pinnedlist"])
