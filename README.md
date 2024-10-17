# AllocationOpt

[![Latest](https://img.shields.io/badge/docs-latest-purple.svg)](https://graphprotocol.github.io/allocation-optimizer/latest/)
[![Build Status](https://github.com/graphprotocol/allocation-optimizer/actions/workflows/CI.yml/badge.svg?branch=)](https://github.com/graphprotocol/allocation-optimizer/actions/workflows/CI.yml?query=branch%3A)
[![Coverage](https://codecov.io/gh/graphprotocol/allocation-optimizer/branch/main/graph/badge.svg)](https://codecov.io/gh/graphprotocol/allocation-optimizer)
[![ColPrac: Contributor's Guide on Collaborative Practices for Community Packages](https://img.shields.io/badge/ColPrac-Contributor's%20Guide-blueviolet)](https://github.com/SciML/ColPrac)


AllocationOpt is a library for optimising the stake distribution for The Graph indexers for indexing rewards [The Graph Protocol](https://thegraph.com/en/).

For details on installation and usage, visit our [documentation](https://graphprotocol.github.io/allocation-optimizer/latest).
For the underlying optimisation method, visit our [blog post](https://semiotic.ai/articles/indexer-allocation-optimisation/).

## Usage

Run the provided binary pointing at the configuration TOML that you would like to use.

``` sh
./app/bin/AllocationOpt /path/to/your_config.toml
```

**NOTE:** This binary only works for x86 Linux.
If you are you a different operating system or architecture, please see the documentation for other options.

**IMPORTANT:** By default, `opt_mode="optimal"`.
Because of our algorithm, `optimal` mode may take a long time to converge.
If this is the case for you, you have two options.
You can use `opt_mode=fastgas`, which runs a different algorithm.
This algorithm is not guaranteed to find the optimal value, and may fail to ever converge (it could hang).
However, it still considers gas unlike the third option `opt_mode=fastnogas`.
This is your fastest option, but it won't take into account gas costs or your preferences for max allocations.
This mode is appropriate when you have negligible gas fees and are okay with allocating to a large number of subgraphs.

## Configuration

An example configuration TOML file might look as below.

``` toml
id = "0x6f8a032b4b1ee622ef2f0fc091bdbb98cfae81a3"
writedir = "data"
max_allocations = 10
whitelist = []
blacklist = []
frozenlist = []
pinnedlist = []
allocation_lifetime = 28
gas = 100
min_signal = 100
verbose = true
num_reported_options = 2
execution_mode = "none"
opt_mode = "optimal"
network_subgraph_endpoint = "https://gateway.thegraph.com/api/{api-key}/subgraphs/id/DZz4kDTdmzWLWsV373w2bSmoar3umKKH9y82SUKr5qmp"
protocol_network = "arbitrum"
syncing_networks = ["mainnet", "gnosis", "arbitrum-one", "arbitrum"]
```

### Detailed Field Descriptions

- `id::String`: The ID of the indexer for whom we're optimising. No default value.
- `network_subgraph_endpoint::String`: The network subgraph endpoint to query. The optimizer
    support any network (such as mainnet, goerli, arbitrum-one, arbitrum-goerli) as long as the
    provided API serves the query requests. If unspecified,
    `"https://api.thegraph.com/subgraphs/name/graphprotocol/graph-network-mainnet"`
- `writedir::String`: The directory to which to write the results of optimisation.
    If don't specify `readdir`, `writedir` also specifies the path to which to save
    the input data tables. If unspecified, `"."`
- `readdir::Union{String, Nothing}`: The directory from which to read saved data tables.
    This speeds up the process as we won't have to query the network subgraph for the
    relevant data. If you don't specify `readdir`, we will query your specified
    `network_subgraph_endpoint` for the data and write it to CSV files in `writedir`.
    This way, you can use your previous `writedir` as your `readdir` in future runs.
    If unspecified, `nothing`
- `whitelist::Vector{String}`: A list of subgraph IPFS hashes that you want to consider
    as candidates to which to allocate. If you leave this empty, we'll assume all subgraphs
    are in the whitelist. If unspecified, `String[]`
- `blacklist::Vector{String}`: A list of subgraph IPFS hashes that you do not want to
    consider allocating to. For example, this list could include broken subgraphs or
    subgraphs that you don't want to index. If unspecified, `String[]`
- `frozenlist::Vector{String}`: If you have open allocations that you don't want to change,
    add the corresponding subgraph IPFS hashes to this list. If unspecified, `String[]`
- `pinnedlist::Vector{String}`: If you have subgraphs that you absolutely want to be
    allocated to, even if only with a negligible amount of GRT, add it to this list.
    If unspecified, `String[]`
- `allocation_lifetime::Integer`: The number of epochs for which you expect the allocations
    the optimiser finds to be open. If unspecified, `28`
- `gas::Real`: The estimated gas cost in GRT to open/close allocations. If unspecified, `100`
- `min_signal::Real`: The minimum amount of signal in GRT that must be on a subgraph
    in order for you to consider allocating to it. If unspecified, `100`
- `max_allocations::Integer`: The maximum number of new allocations you'd like the optimiser
    to consider opening. If unspecified, `10`
- `num_reported_options::Integer`: The number of proposed allocation strategies to report.
    For example, if you select `10` we'd report best 10 allocation strategies ranked by
    profit. Options are reported to a *report.json* in your `writedir`. If unspecified, `1`
- `verbose::Bool`: If true, the optimiser will print details about what it is doing to
    stdout. If unspecified, `false`
- `execution_mode::String`: How the optimiser should execute the allocation strategies it
    finds. Options are `"none"`, which won't do anything, `"actionqueue"`, which will
    push actions to the action queue, and `"rules"`, which will generate indexing rules.
    If unspecified, `"none"`
- `indexer_url::Union{String, Nothing}`: The URL of the indexer management server you want
    to execute the allocation strategies on. If you specify `"actionqueue"`, you must also
    specify `indexer_url`. If unspecified, `nothing`
- `opt_mode::String`: We support three optimisation modes. One is `"fastnogas"`. This mode does
    not consider gas costs and optimises allocation amount over all subgraph deployments.
    Second one is `"fastgas"`. This mode is fast, but may not find the optimal strategy and
    could potentially fail to converge. This mode is also used to the top
    `num_reported_options` allocation strategies. The final mode is `"optimal"`.
    This mode is slower, but it satisfies stronger optimality conditions.
    It will find strategies at least as good as `"fast"`, but not guaranteed to be better.
    By default, `"optimal"`
- `protocol_network::String`: Defines the protocol network that allocation transactions
    should be sent to. The current protocol network options are "mainnet", "goerli",
    "arbitrum", and "arbitrum-goerli". By default, `"mainnet"`
- `syncing_networks::Vector{String}`: The list of syncing networks to support when selecting
    the set of possible subgraphs. This list should match the networks available to your
    graph-node. By default, the list is a singleton of your protocol network

### Example Configurations

#### ActionQueue

Set `execution_mode` to `"actionqueue"` and provide an `indexer_url`.

``` toml
id = "0xd75c4dbcb215a6cf9097cfbcc70aab2596b96a9c"
writedir = "data"
readdir = "data"
max_allocations = 10
whitelist = []
blacklist = []
frozenlist = []
pinnedlist = []
allocation_lifetime = 28
gas = 100
min_signal = 100
verbose = true
num_reported_options = 2
execution_mode = "actionqueue"
indexer_url = "https://localhost:8000"
```

#### Indexer Rules

Change `execution_mode` to `"rules"`.

``` toml
id = "0xd75c4dbcb215a6cf9097cfbcc70aab2596b96a9c"
writedir = "data"
readdir = "data"
max_allocations = 10
whitelist = []
blacklist = []
frozenlist = []
pinnedlist = []
allocation_lifetime = 28
gas = 100
min_signal = 100
verbose = true
num_reported_options = 2
execution_mode = "rules"
```

#### Query Data Instead of Reading Local CSVs

Just don't specify the `readdir`.

``` toml
id = "0xd75c4dbcb215a6cf9097cfbcc70aab2596b96a9c"
writedir = "data"
max_allocations = 10
whitelist = []
blacklist = []
frozenlist = []
pinnedlist = []
allocation_lifetime = 28
gas = 100
min_signal = 100
verbose = true
num_reported_options = 2
execution_mode = "none"
network_subgraph_endpoint = "https://gateway.thegraph.com/api/{api-key}/subgraphs/id/DZz4kDTdmzWLWsV373w2bSmoar3umKKH9y82SUKr5qmp"
protocol_network = "arbitrum"
syncing_networks = ["mainnet", "gnosis", "arbitrum-one", "arbitrum"]
```

#### Quiet Mode

We set `verbose` to `false` here to surpress info messages.

``` toml
id = "0xd75c4dbcb215a6cf9097cfbcc70aab2596b96a9c"
writedir = "data"
readdir = "data"
max_allocations = 10
whitelist = []
blacklist = []
frozenlist = []
pinnedlist = []
allocation_lifetime = 28
gas = 100
min_signal = 100
verbose = false
num_reported_options = 2
execution_mode = "none"
```

#### Whitelisting Subgraphs

Add some subgraph deployment IDs to the `whitelist`.
If, in addition or instead you want to use `blacklist`, `frozenlist`, or `pinnedlist`, you can
similarly add subgraph deployment IDs to those lists.
Notice that we did not change `max_allocations` here.
If `max_allocations` exceeds the number of available subgraphs (2 in this case), the code will
treat the number of available subgraphs as `max_allocations`.

``` toml
id = "0xd75c4dbcb215a6cf9097cfbcc70aab2596b96a9c"
writedir = "data"
readdir = "data"
max_allocations = 10
whitelist = [
    "QmUVskWrz1ZiQZ76AtyhcfFDEH1ELnRpoyEhVL8p6NFTbR",
    "QmcBSr5R3K2M5tk8qeHFaX8pxAhdViYhcKD8ZegYuTcUhC"
]
blacklist = []
frozenlist = []
pinnedlist = []
allocation_lifetime = 28
gas = 100
min_signal = 100
verbose = false
num_reported_options = 2
execution_mode = "none"
```
