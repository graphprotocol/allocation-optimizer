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
julia> x = flextable([
    Dict(
        "ipfsHash" => "Qma",
    ),
])
julia> AllocationOpt.ipfshash(Val(:allocation), x)
```
"""
ipfshash(::Val{:subgraph}, x) = x.ipfsHash
