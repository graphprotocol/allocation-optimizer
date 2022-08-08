```@meta
CurrentModule = AllocationOpt
```

# AllocationOpt

Documentation for [AllocationOpt](https://github.com/graphprotocol/AllocationOpt.jl).

AllocationOpt is a library for optimising how an indexer should allocate its stake in [The Graph Protocol](https://thegraph.com/en/).

!!! warning
    You must run this on a computer that supports 64-bit operations.
    32-bit doesn't have enough precision to solve the optimisation problem.

## Installation

Enter the julia repl. On linux machines, this is as simple as running the `julia` command from your terminal emulator. For MacOS, you'll need to add Julia to your path. See this [StackOverflow post](https://stackoverflow.com/questions/72123620/permission-denied-when-i-am-trying-to-add-julia-to-path-in-macos/72308646#72308646) if you're having issues.
Add this package by adding the github url. First, enter package mode `]`. Then, type `add https://github.com/graphprotocol/AllocationOpt.jl`. You'll also want to add the [Comonicon package](https://github.com/comonicon/Comonicon.jl).

```julia-repl
pkg> add https://github.com/graphprotocol/AllocationOpt.jl/
pkg> add Comonicon
```

## Usage

Download the [*allocationopt* script](https://raw.githubusercontent.com/graphprotocol/AllocationOpt.jl/main/scripts/allocationopt). For example, using `curl` or `wget`. Make sure you use the raw file!

Make the *allocationopt* script executable. 
```bash
$ chmod +x allocationopt
```

You can further simplify the use of this script by symlinking it to your *.local/bin*.
For MacOS, symlink instead to */usr/local/bin*.

```bash
$ mkdir -p ~/.local/bin
$ cd ~/.local/bin
$ ln -s ~/projects/AllocationOpt.jl/scripts/allocationopt .  # Change to the path to the allocationopt script for you
```

You should now be able to run the *allocationopt* script from anywhere!

The optimiser queries the network subgraph data to optimize.
We recommend making queries to the network subgraph served by your own indexer service.
Alternatively, you can supply an API url to `indexer_service_network_url` from the decentralized gateway or hosted service. 
To provide the network subgraph to the optimiser, set the indexer-service flag `--serve-network-subgraph` to `true`.

Populate your preferred lists (whitelist, blacklist, pinnedlist, frozenlist) into a CSV and remember its file path

!!! note
    You can access the help for the optimiser by running the script with the `--help` flag.
    For example `allocationopt --help`.

### Action Queue

This command requires a URL to the indexer management server and a URL to make graph network subgraph queries.

Run the *allocationopt* script with the *actionqueue* option.

```bash
$ ./scripts/allocationopt actionqueue "0x6ac85b9d834b51b14a7b0ed849bb5199e04c05c5" 1 test/example.csv 50.0 28 30 0.3 http://localhost:18000 http://localhost:7600/network
```

!!! note
    You can access the help for the *actionqueue* option of the optimiser by running `allocationopt actionqueue --help` from your terminal.
    The help contains more details about each of the arguments of the optimiser.

Requests from our tool are logged, and you can use the indexer CLI `actions` commands to check and approve actions. 
We do NOT auto-approve actions on your behalf.

### Indexing Rules

If you don't have the action queue set up yet, you can also run the optimiser by telling it to generate indexing rules. 

!!! warning
    Under this setup, you must pay attention to the order in which you execute the rules.
    If you do not close existing allocations before opening new ones, you won't have enough capital to open your new
    allocations.

Run the *allocationopt* script with the *rules* option. The URL passed in should be an API URL

```bash
$ ./scripts/allocationopt rules "0x6ac85b9d834b51b14a7b0ed849bb5199e04c05c5" 1 test/example.csv 50.0 28 25 0.3 http://localhost:7600/network
```

!!! note
    You can access the help for the *rules* option of the optimiser by running `allocationopt rules --help` from your terminal.
    The help contains more details about each of the arguments of the optimiser.


## Bugs and Feature Requests

Please submit bug reports/feature requests to our [issue tracker](https://github.com/graphprotocol/AllocationOpt.jl/issues).
