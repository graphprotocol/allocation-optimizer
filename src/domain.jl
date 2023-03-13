# Copyright 2022-, The Graph Foundation
# SPDX-License-Identifier: MIT

const ethtogrt = 1e18

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
    stakedtokens(::Val{:indexer}, x)

The tokens staked by the indexer in table `x`.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> x = flextable([
    Dict(
        "stakedTokens" => 10,
    ),
])
julia> AllocationOpt.stakedtokens(Val(:indexer), x)
```
"""
stakedtokens(::Val{:indexer}, x) = x.stakedTokens |> only

"""
    stakedtokens(::Val{:subgraph}, x)

The tokens staked on the subgraphs in table `x`.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> x = flextable([
    Dict("stakedTokens" => 10,),
    Dict("stakedTokens" => 5,),
])
julia> AllocationOpt.stakedtokens(Val(:subgraph), x)
```
"""
stakedtokens(::Val{:subgraph}, x) = x.stakedTokens
