# Copyright 2022-, The Graph Foundation
# SPDX-License-Identifier: MIT

"""
    squery()

Return the components of a GraphQL query for subgraphs.

For use with the TheGraphData.jl package.

```julia
julia> using AllocationOpt
julia> value, args, fields = AllocationOpt.squery()
```

# Extended Help
You can find TheGraphData.jl at https://github.com/semiotic-ai/TheGraphData.jl
"""
function squery()
    v = "subgraphDeployments"
    a = Dict{String,Union{Dict{String,String},String}}()
    f = ["ipfsHash", "signalledTokens"]
    return v, a, f
end

"""
    iquery()

Return the components of a GraphQL query for indexers.

For use with the TheGraphData.jl package.

!!! note
    We filter out indexers with stake less than 100k GRT.

```julia
julia> using AllocationOpt
julia> value, args, fields = AllocationOpt.iquery()
```

# Extended Help
You can find TheGraphData.jl at https://github.com/semiotic-ai/TheGraphData.jl
"""
function iquery()
    v = "indexers"
    a = Dict{String,Union{Dict{String,String},String,Int64}}(
        "first" => 1000, "where" => Dict("stakedTokens_gte" => "100000000000000000000000")
    )
    f = ["id", "delegatedTokens", "stakedTokens", "lockedTokens"]
    return v, a, f
end

"""
    aquery()

Return the components of a GraphQL query for allocations.

For use with the TheGraphData.jl package.

```julia
julia> using AllocationOpt
julia> value, args, fields = AllocationOpt.aquery()
```

# Extended Help
You can find TheGraphData.jl at https://github.com/semiotic-ai/TheGraphData.jl
"""
function aquery()
    v = "allocations"
    a = Dict{String,Union{Dict{String,String},String}}(
        "where" => Dict("status" => "Active")
    )
    f = ["allocatedTokens", "subgraphDeployment{ipfsHash}", "indexer{id}"]
    return v, a, f
end

"""
    nquery()

Return the components of a GraphQL query for network parameters.

For use with the TheGraphData.jl package.

```julia
julia> using AllocationOpt
julia> value, args, fields = AllocationOpt.nquery()
```

# Extended Help
You can find TheGraphData.jl at https://github.com/semiotic-ai/TheGraphData.jl
"""
function nquery()
    v = "graphNetwork"
    a = Dict("id" => 1)
    f = [
        "id",
        "totalSupply",
        "networkGRTIssuance",
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
julia> paths = AllocationOpt.path(path)
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
julia> i, a, s, n = AllocationOpt.read("myreaddir", config("verbose" => true))
```
"""
function read(f::AbstractString, config::AbstractDict)
    d = FlexTable[]
    for p in savenames(f)
        config["verbose"] && @info "Reading data from $p"
        push!(d, flextable(@mock(TheGraphData.read(p))))
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
    i = flextable(@mock(paginated_query(iquery()...)))
    a = flextable(flatten.(@mock(paginated_query(aquery()...))))
    s = flextable(@mock(paginated_query(squery()...)))
    n = flextable(@mock(query(nquery()...)))

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
