# Configuration

When using the optimiser, you change it's behaviour via a configuration file specified as a TOML.
The configuration file serves two purposes.
Firstly, it makes it easier for you to track various settings and their impacts.
Secondly, if something breaks, it makes it easier for us to reproduce what went wrong.

An example configuration TOML file might look as below.

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
execution_mode = "none"
opt_mode = "fast"
protocol_network = "mainnet"
syncing_networks = ["mainnet"]
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
protocol_network = "arbitrum"
syncing_network = ["mainnet"]
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

#### Query data Instead of Reading Local CSVs

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
```

#### Query data for specified networks

Specify the network subgraph endpoint for networks other than The Graph network on Ethereum mainnet. Here we use the endpoint to goerli network subgraph.

``` toml
id = "0xE9a1CABd57700B17945Fd81feeFba82340D9568F"
network_subgraph_endpoint = "https://api.thegraph.com/subgraphs/name/graphprotocol/graph-network-goerli"
```

Other available endpoints examples are
- Mainnet (default): https://api.thegraph.com/subgraphs/name/graphprotocol/graph-network-mainnet
- Arbitrum-One: https://api.thegraph.com/subgraphs/name/graphprotocol/graph-network-arbitrum
- Arbitrum-Goerli: https://api.thegraph.com/subgraphs/name/graphprotocol/graph-network-arbitrum-goerli

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


