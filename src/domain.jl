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
1.0e-18
```
"""
togrt(x::AbstractString) = parse(Float64, x) / ethtogrt

"""
    blockissuance(::Val{:network}, x)

The tokens issued per block.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> n = flextable([
    Dict(
        "id" => 1,
        "networkGRTIssuancePerBlock" => 1,
        "epochLength" => 28,
        "totalTokensSignalled" => 2,
        "currentEpoch" => 1,
    )
])
julia> AllocationOpt.blockissuance(Val(:network), n)
1
"""
blockissuance(::Val{:network}, x) = x.networkGRTIssuancePerBlock |> only

"""
    blocksperepoch(::Val{:network}, x)

The number of blocks in each epoch.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> n = flextable([
    Dict(
        "id" => 1,
        "networkGRTIssuancePerBlock" => 1,
        "epochLength" => 28,
        "totalTokensSignalled" => 2,
        "currentEpoch" => 1,
    )
])
julia> AllocationOpt.blocksperepoch(Val(:network), n)
28
"""
blocksperepoch(::Val{:network}, x) = x.epochLength |> only

"""
    signal(::Val{:network}, x)

The total signal in the network

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> n = flextable([
    Dict(
        "id" => 1,
        "networkGRTIssuancePerBlock" => 1,
        "epochLength" => 28,
        "totalTokensSignalled" => 2,
        "currentEpoch" => 1,
    )
])
julia> AllocationOpt.signal(Val(:network), n)
2
"""
signal(::Val{:network}, x) = x.totalTokensSignalled |> only

"""
    currentepoch(::Val{:network}, x)

The current epoch.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> n = flextable([
    Dict(
        "id" => 1,
        "networkGRTIssuancePerBlock" => 1,
        "epochLength" => 28,
        "totalTokensSignalled" => 2,
        "currentEpoch" => 1,
    )
])
julia> AllocationOpt.currentepoch(Val(:network), n)
1
"""
currentepoch(::Val{:network}, x) = x.currentEpoch |> only

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
1-element view(lazystack(::Vector{Vector{String}}), 1, :) with eltype String:
 "Qma"
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
        "allocatedTokens" => 1,
    ),
])
julia> AllocationOpt.stake(Val(:allocation), x)
1-element view(transpose(lazystack(::Vector{Vector{Int64}})), :, 1) with eltype Int64:
 1
```
"""
stake(::Val{:allocation}, x) = x.allocatedTokens

"""
    id(::Val{:allocation}, x)

Get the allocation id for each allocation in `x`.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> x = flextable([
    Dict(
        "id" => "0x1"
    ),
])
julia> AllocationOpt.id(Val(:allocation), x)
1-element view(lazystack(::Vector{Vector{String}}), 1, :) with eltype String:
 "0x1"
```
"""
id(::Val{:allocation}, x) = x.id

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
julia> AllocationOpt.ipfshash(Val(:subgraph), x)
1-element view(lazystack(::Vector{Vector{String}}), 1, :) with eltype String:
 "Qma"
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
2-element view(transpose(lazystack(::Vector{Vector{Int64}})), :, 1) with eltype Int64:
 10
  5
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
2-element view(transpose(lazystack(::Vector{Vector{Int64}})), :, 1) with eltype Int64:
 10
  5
```
"""
signal(::Val{:subgraph}, x) = x.signalledTokens

"""
    deniedat(::Val{:subgraph}, x)

If this value is non-zero, the subgraph doesn't receive indexing rewards.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> x = flextable([
    Dict("deniedAt" => 10,),
    Dict("deniedAt" => 0,),
])
julia> AllocationOpt.deniedat(Val(:subgraph), x)
2-element view(transpose(lazystack(::Vector{Vector{Int64}})), :, 1) with eltype Int64:
 10
  0
```
"""
deniedat(::Val{:subgraph}, x) = x.deniedAt

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
10
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
10
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
10
```
"""
locked(::Val{:indexer}, x) = x.lockedTokens |> only

"""
    available(::Val{:indexer}, x)

The tokens available for the indexer to allocate in table `x`.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> x = flextable([
    Dict(
        "stakedTokens" => 10,
        "delegatedTokens" => 20,
        "lockedTokens" => 5,
    ),
])
julia> AllocationOpt.availablestake(Val(:indexer), x)
25.0
```
"""
function availablestake(::Val{:indexer}, x)
    val = Val(:indexer)
    return stake(val, x) + delegation(val, x) - locked(val, x)
end

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
15.0
```
"""
function frozen(a::FlexTable, config::AbstractDict)
    frozenallocs = SAC.filterview(
        r -> ipfshash(Val(:allocation), r) ∈ config["frozenlist"], a
    )
    return sum(stake(Val(:allocation), frozenallocs); init=0.0)
end

"""
    pinned(config::AbstractDict)

The pinned vector of the indexer.

```julia
julia> using AllocationOpt
julia> s = flextable([
    Dict("ipfsHash" => "Qma", "signalledTokens" => 5.0),
    Dict("ipfsHash" => "Qmb", "signalledTokens" => 10.0),
    Dict("ipfsHash" => "Qmc", "signalledTokens" => 15.0),
])
julia> config = Dict("pinnedlist" => ["Qma", "Qmb"])
julia> AllocationOpt.pinned(s, config)
3-element Vector{Float64}:
 0.1
 0.1
 0.0
```
"""
function pinned(s::FlexTable, config::AbstractDict)
    pinnedixs = findall(r -> ipfshash(Val(:subgraph), r) ∈ config["pinnedlist"], s)
    v = zeros(length(s))
    v[pinnedixs] .= pinnedamount
    return v
end

"""
     allocatablesubgraphs(s::FlexTable, config::AbstractDict)

For the subgraphs `s` return a view of the subgraphs on which we can allocate.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> s = flextable([
            Dict("ipfsHash" => "Qma", "signalledTokens" => 10,),
            Dict("ipfsHash" => "Qmb", "signalledTokens" => 20),
            Dict("ipfsHash" => "Qmc", "signalledTokens" => 5),
       ])
julia> config = Dict(
            "whitelist" => String["Qmb", "Qmc"],
            "blacklist" => String[],
            "frozenlist" => String[],
            "pinnedlist" => String[],
            "min_signal" => 0.0
)
julia> fs = AllocationOpt.allocatablesubgraphs(s, config)
FlexTable with 2 columns and 2 rows:
     signalledTokens  ipfsHash
   ┌──────────────────────────
 1 │ 20               Qmb
 2 │ 5                Qmc
```
"""
function allocatablesubgraphs(s::FlexTable, config::AbstractDict)
    # If no whitelist, whitelist is all subgraphs. Pinned subgraphs are treated as whitelisted.
    whitelist = if isempty(config["whitelist"])
        ipfshash(Val(:subgraph), s)
    else
        config["whitelist"] ∪ config["pinnedlist"]
    end

    # For filtering, blacklist contains both the blacklist and frozenlist,
    # since frozen allocations aren't considered during optimisation.
    blacklist = config["blacklist"] ∪ config["frozenlist"]

    # Anonymous function that returns true if an ipfshash is in the
    # whitelist and not in the blacklist
    f = x -> x ∈ whitelist && !(x ∈ blacklist)

    # Only choose subgraphs with enough signal
    minsignal = config["min_signal"]
    g = x -> x ≥ minsignal

    # Filter the subgraph table by our anonymous function
    fs = SAC.filterview(s) do r
        x = ipfshash(Val(:subgraph), r)
        y = signal(Val(:subgraph), r)
        return f(x) && g(y)
    end
    return fs
end

"""
    newtokenissuance(n::FlexTable, config::Dict)

How many new tokens are issued over the allocation lifetime given network parameters `n`. Calcualted by networkGRTIssuancePerBlock * epochLength * allocation_lifetime

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> n = flextable([
            Dict(
                "id" => 1,
                "networkGRTIssuancePerBlock" => 2,
                "epochLength" => 1,
                "totalTokensSignalled" => 2,
                "currentEpoch" => 1,
            )
        ])
julia> config = Dict("allocation_lifetime" => 1)
julia> AllocationOpt.newtokenissuance(n, config)
1.0
```
"""
function newtokenissuance(n::FlexTable, config::Dict)
    r = blockissuance(Val(:network), n)
    t = blocksperepoch(Val(:network), n) * config["allocation_lifetime"]

    newtokens = r * t
    return newtokens
end

"""
    indexingreward(
        ixs::AbstractArray{Integer},
        x::AbstractVector{Real},
        Ω::AbstractVector{Real},
        ψ::AbstractVector{Real},
        Φ::Real,
        Ψ::Real
    )

The indexing rewards for the allocation vector `x` given signals `ψ`, the existing
allocations on subgraphs `Ω`, token issuance `Φ`, and total signal `Ψ`. Here `ixs`
is a vector of indices `Ω`, and `ψ`. `x` will be filtered by `SemioticOpt`, so we
don't do this here.


```julia
julia> using AllocationOpt
julia> ixs = Int32[2]
julia> ψ = [0.0, 1.0]
julia> Ω = [1.0, 1.0]
julia> Φ = 1.0
julia> Ψ = 2.0
julia> x = [0.0, 1.0]
julia> AllocationOpt.indexingreward(ixs, x, Ω, ψ, Φ, Ψ)
0.25
````
"""
function indexingreward(
    ixs::AbstractArray{I},
    x::AbstractVector{T},
    Ω::AbstractVector{T},
    ψ::AbstractVector{T},
    Φ::Real,
    Ψ::Real,
) where {T<:Real,I<:Integer}
    return indexingreward(x, Ω[ixs], ψ[ixs], Φ, Ψ)
end

"""
    indexingreward(
        x::AbstractVector{Real},
        Ω::AbstractVector{Real},
        ψ::AbstractVector{Real},
        Φ::Real,
        Ψ::Real
    )

The indexing rewards for the allocation vector `x` given signals `ψ`, the existing
allocations on subgraphs `Ω`, token issuance `Φ`, and total signal `Ψ`.

```julia
julia> using AllocationOpt
julia> ψ = [0.0, 1.0]
julia> Ω = [1.0, 1.0]
julia> Φ = 1.0
julia> Ψ = 2.0
julia> x = [0.0, 1.0]
julia> AllocationOpt.indexingreward(x, Ω, ψ, Φ, Ψ)
0.25
```
"""
function indexingreward(
    x::AbstractVector{T}, Ω::AbstractVector{T}, ψ::AbstractVector{T}, Φ::Real, Ψ::Real
) where {T<:Real}
    return indexingreward.(x, Ω, ψ, Φ, Ψ) |> sum
end

"""
    indexingreward(x::Real, Ω::Real, ψ::Real, Φ::Real, Ψ::Real)

The indexing rewards for the allocation scalar `x` given signals `ψ`, the existing
allocation on subgraphs `Ω`, token issuance `Φ`, and total signal `Ψ`.

```julia
julia> using AllocationOpt
julia> ψ = 0.0
julia> Ω = 1.0
julia> Φ = 1.0
julia> Ψ = 2.0
julia> x = 1.0
julia> AllocationOpt.indexingreward(x, Ω, ψ, Φ, Ψ)
0.0
```
"""
function indexingreward(x::Real, Ω::Real, ψ::Real, Φ::Real, Ψ::Real)
    sr = Φ * ψ / Ψ
    return sr * x / (x + Ω)
end

"""
    profit(r::Real, g::Real)

Compute the profit for one allocation with reward `r` and gas cost `g`.

```julia
julia> using AllocationOpt
julia> r = 10
julia> g = 1
julia> AllocationOpt.profit(r, g)
9
```
"""
profit(r::Real, g::Real) = r == 0 ? 0 : r - g

"""
    deniedzeroixs(s::FlexTable)

Find the indices of subgraphs that have "deniedAt" equal to zero.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> s = flextable([
           Dict("ipfsHash" => "Qma", "signalledTokens" => 5.0, "deniedAt" => 0),
           Dict("ipfsHash" => "Qmb", "signalledTokens" => 10.0, "deniedAt" => 10),
           Dict("ipfsHash" => "Qmc", "signalledTokens" => 15.0, "deniedAt" => 0),
       ])
julia> AllocationOpt.deniedzeroixs(s)
2-element Vector{Int64}:
 1
 3
```
"""
deniedzeroixs(s::FlexTable) = findall(r -> deniedat(Val(:subgraph), r) == 0, s)
