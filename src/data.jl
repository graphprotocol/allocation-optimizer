# Copyright 2022-, The Graph Foundation
# SPDX-Licen se-Identifier: MIT

"""
    squery(config::AbstractDict)

Return the components of a GraphQL query for subgraphs.

For use with the TheGraphData.jl package.

```julia
julia> using AllocationOpt
julia> config = Dict("syncing_networking" => ["mainnet"])
julia> value, args, fields = AllocationOpt.squery(config)
("subgraphDeployments", Dict{String, Union{Dict{String, String}, String}}(), ["ipfsHash", "signalledTokens", "stakedTokens"])
```

# Extended Help
You can find TheGraphData.jl at https://github.com/semiotic-ai/TheGraphData.jl
"""
function squery(config::AbstractDict)
    v = "subgraphDeployments"
    a = Dict{String,Any}(
        "where" => Dict{String,Any}(
            "manifest_" => Dict{String,Any}("network_in" => config["syncing_networks"])
        ),
    )
    f = ["ipfsHash", "signalledTokens", "stakedTokens", "deniedAt"]
    return v, a, f
end

"""
    iquery(id::AbstractString)

Return the components of a GraphQL query for the stake of indexer `id`.

For use with the TheGraphData.jl package.

```julia
julia> using AllocationOpt
julia> id = "0xa"
julia> value, args, fields = AllocationOpt.iquery(id)
("indexer", Dict{String, Union{Int64, Dict{String, String}, String}}("id" => "0xa"), ["delegatedTokens", "stakedTokens", "lockedTokens"])
```

# Extended Help
You can find TheGraphData.jl at https://github.com/semiotic-ai/TheGraphData.jl
"""
function iquery(id::AbstractString)
    v = "indexer"
    a = Dict{String,Union{Dict{String,String},String,Int64}}("id" => id)
    f = ["delegatedTokens", "stakedTokens", "lockedTokens"]
    return v, a, f
end

"""
    aquery(id::AbstractString)

Return the components of a GraphQL query for active allocations of indexer `id`.

For use with the TheGraphData.jl package.

```julia
julia> using AllocationOpt
julia> id = "0xa"
julia> value, args, fields = AllocationOpt.aquery(id)
("allocations", Dict{String, Union{Dict{String, String}, String}}("where" => Dict("status" => "Active", "indexer" => "0xa")), ["allocatedTokens", "id", "subgraphDeployment{ipfsHash}"])
```

# Extended Help
You can find TheGraphData.jl at https://github.com/semiotic-ai/TheGraphData.jl
"""
function aquery(id::AbstractString)
    v = "allocations"
    a = Dict{String,Union{Dict{String,String},String}}(
        "where" => Dict("status" => "Active", "indexer" => id)
    )
    f = ["allocatedTokens", "id", "subgraphDeployment{ipfsHash}"]
    return v, a, f
end

"""
    nquery()

Return the components of a GraphQL query for network parameters.

For use with the TheGraphData.jl package.

```julia
julia> using AllocationOpt
julia> value, args, fields = AllocationOpt.nquery()
("graphNetwork", Dict("id" => 1), ["id", "networkGRTIssuance", "epochLength", "totalTokensSignalled", "currentEpoch"])
```

# Extended Help
You can find TheGraphData.jl at https://github.com/semiotic-ai/TheGraphData.jl
"""
function nquery()
    v = "graphNetwork"
    a = Dict("id" => 1)
    f = [
        "id",
        "networkGRTIssuancePerBlock",
        "epochLength",
        "totalTokensSignalled",
        "currentEpoch",
    ]
    return v, a, f
end

"""
    savenames(p::AbstractString)

Return a generator of the generic names of the CSV files containing the data with the
path specified by `p`.

```julia
julia> using AllocationOpt
julia> path = "mypath"
julia> paths = AllocationOpt.savenames(path)
Base.Generator{NTuple{4, String}, AllocationOpt.var"#1#2"{String}}(AllocationOpt.var"#1#2"{String}("mypath"), ("indexer.csv", "allocation.csv", "subgraph.csv", "network.csv"))
```
"""
function savenames(p::AbstractString)
    return Base.Generator(
        x -> joinpath(p, x),
        ("indexer.csv", "allocation.csv", "subgraph.csv", "network.csv"),
    )
end

"""
    read(f::AbstractString, config::AbstractDict)

Read the CSV files from `f` and return the tables from those files.

```julia
julia> using AllocationOpt
julia> i, a, s, n = AllocationOpt.read("myreaddir", Dict("verbose" => true))
```
"""
function read(f::AbstractString, config::AbstractDict)
    d = FlexTable[]
    for p in savenames(f)
        config["verbose"] && @info "Reading data from $p"
        try
            push!(d, flextable(@mock(TheGraphData.read(p))))
        catch e
            ArgumentError(
                "Could not read $p. If you meant to query the network subgraph, remove the `readdir` argument from the config. Else your specified `readdir` is probably incorrect.",
            ) |> throw
        end
    end
    i, a, s, n = d
    return i, a, s, n
end

"""
    read(::Nothing, config::AbstractDict)

Query the required data from the provided endpoint in the `config`.

```julia
julia> using AllocationOpt
julia> config = Dict(
            "verbose" => true,
            "network_subgraph_endpoint" => "https://api.thegraph.com/subgraphs/name/graphprotocol/graph-network-mainnet",
        )
julia> i, a, s, n = AllocationOpt.read(nothing, config)
```
"""
function read(::Nothing, config::AbstractDict{String,Any})
    url = config["network_subgraph_endpoint"]
    client!(url)
    config["verbose"] && @info "Querying data from $url"
    i = flextable(@mock(query(iquery(config["id"])...)))
    d = flatten.(@mock(paginated_query(aquery(config["id"])...)))
    a = if isempty(d)
        FlexTable(
            Dict(
                key => String[] for
                key in ["subgraphDeployment.ipfsHash", "allocatedTokens", "id"]
            ),
        )
    else
        flextable(d)
    end

    s = flextable(@mock(paginated_query(squery(config)...)))
    n = flextable(@mock(query(nquery()...)))

    # Convert string types to GRT
    i, a, s, n = correcttypes!(i, a, s, n)

    # Subtract indexer allocations from total allocation on subgraph
    a, s = subtractindexer!(a, s)

    return i, a, s, n
end

"""
    read(config::AbstractDict)

Given a `config`, read the data in as flextables.

If you have specified a "readdir" in the config, this will read from CSV files in that
directory. Otherwise, this will query the specified `"network_subgraph_endpoint"`

```julia
julia> using AllocationOpt
julia> config = Dict("verbose" => false, "readdir" => "mydatadir")
julia> i, a, s, n = AllocationOpt.read(config)  # Read data from CSVs
```

```julia
julia> using AllocationOpt
julia> config = Dict(
    "verbose" => false,
    "network_subgraph_endpoint" => "https://api.thegraph.com/subgraphs/name/graphprotocol/graph-network-mainnet",
    "readdir" => nothing,
)
julia> i, a, s, n = AllocationOpt.read(config)  # Query GQL endpoint
```
"""
function read(config::AbstractDict{String,Any})
    readdir::Union{String,Nothing} = config["readdir"]
    i, a, s, n = read(readdir, config)
    return i, a, s, n
end

"""
    write(i::FlexTable, a::FlexTable, s::FlexTable, n::FlexTable, config::AbstractDict)

Write the tables to the `writedir` specified in the `config`.


```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> config = Dict("verbose" => true, "writedir" => "datadir")
julia> t = flextable([
            Dict("ipfsHash" => "Qma", "signalledTokens" => "1"),
            Dict("ipfsHash" => "Qmb", "signalledTokens" => "2"),
        ])
julia> i, a, s, n = repeat([t,], 4)
juila> AllocationOpt.write(i, a, s, n, config)
```
"""
function write(i::FlexTable, a::FlexTable, s::FlexTable, n::FlexTable, config::AbstractDict)
    writedir = config["writedir"]
    ps = String[]
    for (d, p) in zip((i, a, s, n), savenames(writedir))
        config["verbose"] && @info "Writing table to $p"
        push!(ps, @mock(TheGraphData.write(p, d)))
    end
    return ps
end

"""
    correcttypes!(::Val{:indexer}, i::FlexTable)

Convert the string currency fields in the indexer table to be in GRT.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> i = flextable([
    Dict(
        "stakedTokens" => "1",
        "delegatedTokens" => "0",
        "id" => "0xa",
        "lockedTokens" => "0",
    ),
])
julia> AllocationOpt.correcttypes!(Val(:indexer), i)
FlexTable with 4 columns and 1 row:
     stakedTokens  delegatedTokens  id   lockedTokens
   ┌─────────────────────────────────────────────────
 1 │ 1.0e-18       0.0              0xa  0.0
```
"""
function correcttypes!(::Val{:indexer}, i::FlexTable)
    i.stakedTokens = i.stakedTokens .|> togrt
    i.delegatedTokens = i.delegatedTokens .|> togrt
    i.lockedTokens = i.lockedTokens .|> togrt
    return i
end

"""
    correcttypes!(::Val{:subgraph}, s::FlexTable)

Convert the string currency fields in the subgraph table to be in GRT.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> s = flextable([
    Dict(
        "stakedTokens" => "1",
        "signalledTokens" => "0",
        "ipfsHash" => "Qma",
        "deniedAt" => 0,
    ),
])
julia> AllocationOpt.correcttypes!(Val(:subgraph), s)
FlexTable with 4 columns and 1 row:
     deniedAt  stakedTokens  signalledTokens  ipfsHash
   ┌──────────────────────────────────────────────────
 1 │ 0         1.0e-18       0.0              Qma
```
"""
function correcttypes!(::Val{:subgraph}, s::FlexTable)
    s.stakedTokens = s.stakedTokens .|> togrt
    s.signalledTokens = s.signalledTokens .|> togrt
    return s
end

"""
    correcttypes!(::Val{:allocation}, a::FlexTable)

Convert the string currency fields in the allocation table to be in GRT.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> a = flextable([
    Dict(
        "allocatedTokens" => "1",
        "subgraphDeployment.ipfsHash" => "Qma",
    ),
])
julia> AllocationOpt.correcttypes!(Val(:allocation), a)
FlexTable with 2 columns and 1 row:
     subgraphDeployment.ipfsHash  allocatedTokens
   ┌─────────────────────────────────────────────
 1 │ Qma                          1.0e-18
```
"""
function correcttypes!(::Val{:allocation}, a::FlexTable)
    a.allocatedTokens = a.allocatedTokens .|> togrt
    return a
end

"""
    correcttypes!(::Val{:network}, n::FlexTable)

Convert the string currency fields in the network table to be in GRT.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> n = flextable([
    Dict(
        "id" => 1,
        "networkGRTIssuancePerBlock" => "1",
        "epochLength" => 28,
        "totalTokensSignalled" => "2",
        "currentEpoch" => 1,
    )
])
julia> AllocationOpt.correcttypes!(Val(:network), n)
FlexTable with 6 columns and 1 row:
    totalTokensSignalled  currentEpoch  id  networkGRTIssuancePerBlock  epochLength
┌────────────────────────────────────────────────────────────────────────────────
1 │ 2.0e-18               1             1   1.0e-18                     28
```
"""
function correcttypes!(::Val{:network}, n::FlexTable)
    n.totalTokensSignalled = n.totalTokensSignalled .|> togrt
    n.networkGRTIssuancePerBlock = n.networkGRTIssuancePerBlock .|> togrt
    return n
end

"""
    correcttypes!(i::FlexTable, a::FlexTable, s::FlexTable, n::FlexTable)

Convert all tables to be in GRT.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> i = flextable([
    Dict(
        "stakedTokens" => "1",
        "delegatedTokens" => "0",
        "id" => "0xa",
        "lockedTokens" => "0",
    ),
])
julia> s = flextable([
    Dict(
        "stakedTokens" => "1",
        "signalledTokens" => "0",
        "ipfsHash" => "Qma",
    ),
])
julia> a = flextable([
    Dict(
        "allocatedTokens" => "1",
        "subgraphDeployment.ipfsHash" => "Qma",
    ),
])
julia> n = flextable([
    Dict(
        "id" => 1,
        "networkGRTIssuancePerBlock" => "1",
        "epochLength" => 28,
        "totalTokensSignalled" => "2",
        "currentEpoch" => 1,
    )
])
julia> i, a, s, n = AllocationOpt.correcttypes!(i, a, s, n)
```
"""
function correcttypes!(i::FlexTable, a::FlexTable, s::FlexTable, n::FlexTable)
    i = correcttypes!(Val(:indexer), i)
    a = correcttypes!(Val(:allocation), a)
    s = correcttypes!(Val(:subgraph), s)
    n = correcttypes!(Val(:network), n)
    return i, a, s, n
end

"""
    subtractindexer!(a::FlexTable, s::FlexTable)

Subtract the indexer's allocated tokens from the total allocated tokens on each subgraph.

```julia
julia> using AllocationOpt
julia> using TheGraphData
julia> s = flextable([
            Dict("ipfsHash" => "Qmb", "stakedTokens" => 20),
            Dict("ipfsHash" => "Qma", "stakedTokens" => 10),
            Dict("ipfsHash" => "Qmc", "stakedTokens" => 5),
        ])
julia> a = flextable([
            Dict("subgraphDeployment.ipfsHash" => "Qma", "allocatedTokens" => 5, "id" => "0xa"),
            Dict("subgraphDeployment.ipfsHash" => "Qmb", "allocatedTokens" => 10, "id" => "0xb"),
        ])
julia> a, s = AllocationOpt.subtractindexer!(a, s)
(NamedTuple[(var"subgraphDeployment.ipfsHash" = "Qma", allocatedTokens = 5, id = "0xa"), (var"subgraphDeployment.ipfsHash" = "Qmb", allocatedTokens = 10, id = "0xb")], NamedTuple[(stakedTokens = 5.0, ipfsHash = "Qma"), (stakedTokens = 10, ipfsHash = "Qmb"), (stakedTokens = 5, ipfsHash = "Qmc")])
```
"""
function subtractindexer!(a::FlexTable, s::FlexTable)
    # O(N) algorithm rather than using joins, which would be O(MN)

    # Sort both tables by ipfshash
    s = sort(s; by=getproperty(:ipfsHash))
    a = sort(a; by=getproperty(Symbol("subgraphDeployment.ipfsHash")))

    na = length(a)
    # Return early if there's no allocations
    if isempty(a)
        return a, s
    end

    # Preallocate vector of staked tokens on subgraphs
    ts = stake(Val(:subgraph), s)

    # Loop over subgraphs
    # If the subgraph ipfs == the allocation hash:
    # Update the staked tokens
    # If we've gone through all the allocations, break
    # Else, update the allocation table index and get the new allocation subgraph hash
    ix = 1
    aix = ipfshash(Val(:allocation), a)[ix]
    for (i, rs) in enumerate(s)
        if ipfshash(Val(:subgraph), rs) == aix
            ts[i] = stake(Val(:subgraph), rs) - stake(Val(:allocation), a[ix])
            if ix == na
                break
            end
            ix += 1
            aix = ipfshash(Val(:allocation), a)[ix]
        end
    end

    # Update the staked tokens
    s.stakedTokens = ts

    return a, s
end
