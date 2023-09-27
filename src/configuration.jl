# Copyright 2022-, The Graph Foundation
# SPDX-License-Identifier: MIT

"""
    configuredefaults!(config::AbstractDict)

Set default values for the config dictionary if the value was not specified in the config file.

# Config Specification
- `id::String`: The ID of the indexer for whom we're optimising. No default value.
- `network_subgraph_endpoint::String`: The network subgraph endpoint to query.
    By default, `"https://api.thegraph.com/subgraphs/name/graphprotocol/graph-network-mainnet"`
- `writedir::String`: The directory to which to write the results of optimisation.
    If don't specify `readdir`, `writedir` also specifies the path to which to save
    the input data tables. By default, `"."`
- `readdir::Union{String, Nothing}`: The directory from which to read saved data tables.
    This speeds up the process as we won't have to query the network subgraph for the
    relevant data. If you don't specify `readdir`, we will query your specified
    `network_subgraph_endpoint` for the data and write it to CSV files in `writedir`.
    This way, you can use your previous `writedir` as your `readdir` in future runs.
    By default, `nothing`
- `whitelist::Vector{String}`: A list of subgraph IPFS hashes that you want to consider
    as candidates to which to allocate. If you leave this empty, we'll assume all subgraphs
    are in the whitelist. By default, `String[]`
- `blacklist::Vector{String}`: A list of subgraph IPFS hashes that you do not want to
    consider allocating to. For example, this list could include broken subgraphs or
    subgraphs that you don't want to index. By default, `String[]`
- `frozenlist::Vector{String}`: If you have open allocations that you don't want to change,
    add the corresponding subgraph IPFS hashes to this list. By default, `String[]`
- `pinnedlist::Vector{String}`: If you have subgraphs that you absolutely want to be
    allocated to, even if only with a negligible amount of GRT, add it to this list.
    By default, `String[]`
- `allocation_lifetime::Integer`: The number of epochs for which you expect the allocations
    the optimiser finds to be open. By default, `28`
- `gas::Real`: The estimated gas cost in GRT to open/close allocations. By default, `100`
- `min_signal::Real`: The minimum amount of signal in GRT that must be on a subgraph
    in order for you to consider allocating to it. By default, `100`
- `max_allocations::Integer`: The maximum number of new allocations you'd like the optimiser
    to consider opening. By default, `10`
- `num_reported_options::Integer`: The number of proposed allocation strategies to report.
    For example, if you select `10` we'd report best 10 allocation strategies ranked by
    profit. By default, `1`
- `verbose::Bool`: If true, the optimiser will print details about what it is doing to
    stdout. By default, `false`
- `execution_mode::String`: How the optimiser should execute the allocation strategies it
    finds. Options are `"none"`, which won't do anything, `"actionqueue"`, which will
    push actions to the action queue, and `"rules"`, which will generate indexing rules.
    By default, `"none"`
- `indexer_url::Union{String, Nothing}`: The URL of the indexer management server you want
    to execute the allocation strategies on. If you specify `"actionqueue"`, you must also
    specify `indexer_url`. By default, `nothing`
- `opt_mode::String`: We support two optimisation modes. One is `"fast"`. This mode is
    fast, but may not find the optimal strategy. This mode is also used to the top
    `num_reported_options` allocation strategies. The other mode is `"optimal"`. This
    mode is slower, but it satisfy stronger optimality conditions. It will find strategies
    at least as good as `"fast"`, but not guaranteed to be better. In general, we recommend
    exploring config options using `"fast"` mode first, and then using `"optimal"`
    mode to find the optimal allocation. By default, `"optimal"`
- `protocol_network::String`: Defines the protocol network that allocation transactions 
    should be sent to. The current protocol network options are "mainnet", "goerli", 
    "arbitrum", and "arbitrum-goerli". By default, `"mainnet"`
- `syncing_networks::Vector{String}`: The list of syncing networks to support when selecting 
    the set of possible subgraphs. This list should match the networks available to your 
    graph-node. By default, the list is a singleton of your protocol network

```julia
julia> using AllocationOpt
julia> config = Dict{String, Any}("id" => "0xa")
julia> config = AllocationOpt.configuredefaults!(config)
Dict{String, Any} with 16 entries:
  "execution_mode"            => "none"
  "readdir"                   => nothing
  "writedir"                  => "."
  "num_reported_options"      => 1
  "id"                        => "0xa"
  "pinnedlist"                => String[]
  "indexer_url"               => nothing
  "gas"                       => 100
  "allocation_lifetime"       => 28
  "blacklist"                 => String[]
  "verbose"                   => false
  "min_signal"                => 100
  "network_subgraph_endpoint" => "https://api.thegraph.com/subgraphs/name/graphprotocol/graph-network-mainnet"
  "whitelist"                 => String[]
  "protocol_network"          => "mainnet"
  "syncing_networks"          => String["mainnet"]
```
"""
function configuredefaults!(config::AbstractDict)
    @assert haskey(config, "id")
    setdefault!(
        config,
        "network_subgraph_endpoint",
        "https://api.thegraph.com/subgraphs/name/graphprotocol/graph-network-mainnet",
    )
    setdefault!(config, "writedir", ".")
    setdefault!(config, "readdir", nothing)
    setdefault!(config, "whitelist", String[])
    setdefault!(config, "blacklist", String[])
    setdefault!(config, "frozenlist", String[])
    setdefault!(config, "pinnedlist", String[])
    setdefault!(config, "allocation_lifetime", 28)
    setdefault!(config, "gas", 100)
    setdefault!(config, "min_signal", 100)
    setdefault!(config, "max_allocations", 10)
    setdefault!(config, "num_reported_options", 1)
    setdefault!(config, "indexer_url", nothing)
    setdefault!(config, "execution_mode", "none")
    setdefault!(config, "verbose", false)
    setdefault!(config, "opt_mode", "optimal")
    setdefault!(config, "protocol_network", "mainnet")
    setdefault!(config, "syncing_networks", String[config["protocol_network"]])
    return config
end

"""
    formatconfig!(config::AbstractDict)

Given a `config`, reformat values that need to be standardised.

```julia
julia> using AllocationOpt
julia> config = Dict("id" => "0xA")
julia> AllocationOpt.formatconfig!(config)
Dict{String, String} with 1 entry:
  "id" => "0xa"
```
"""
function formatconfig!(config::AbstractDict)
    config["id"] = config["id"] |> lowercase
    return config
end

"""
    readconfig(p::AbstractString)

Read the config file from path `p`. The config file must be specifed as a TOML.

See [`configuredefaults!`](@ref) to see which fields you should specify in the config.

```julia
julia> using AllocationOpt
julia> path = "myconfig.toml"
julia> config = AllocationOpt.readconfig(path)
Dict{String, Any} with 13 entries:
  "execution_mode"       => "none"
  "writedir"             => "data"
  "num_reported_options" => 2
  "id"                   => "0xd75c4dbcb215a6cf9097cfbcc70aab2596b96a9c"
  "pinnedlist"           => Union{}[]
  "gas"                  => 100
  "allocation_lifetime"  => 28
  "blacklist"            => Union{}[]
  "verbose"              => true
  "min_signal"           => 100
  "whitelist"            => Union{}[]
  "max_allocations"      => 5
  "frozenlist"           => Union{}[]
  "protocol_network"     => "mainnet"
  "syncing_networks"     => String["mainnet", "gnosis"]
```
"""
readconfig(p::AbstractString) = p |> TOML.parsefile
