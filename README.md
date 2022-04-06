# AllocationOpt

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://graphprotocol.github.io/AllocationOpt.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://graphprotocol.github.io/AllocationOpt.jl/dev)
[![Build Status](https://github.com/graphprotocol/AllocationOpt.jl/actions/workflows/CI.yml/badge.svg?branch=)](https://github.com/graphprotocol/AllocationOpt.jl/actions/workflows/CI.yml?query=branch%3A)
[![Coverage](https://codecov.io/gh/graphprotocol/AllocationOpt.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/graphprotocol/AllocationOpt.jl)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)


## Installation

1. Clone this github repository.

```bash
$ git clone git@github.com:graphprotocol/AllocationOpt.jl.git
```

1. [Download](https://julialang.org/downloads/) and install julia locally. You'll need at least Julia 1.7 in order to use this tool.
2. Enter the julia repl. On linux machines, this is as simple as running the `julia` command from your terminal emulator.
3. Enter *shell mode* by typing `;` in the repl.
4. `cd` into the AllocationOpt directory. For example

```julia-repl
shell> cd projects/AllocationOpt.jl
```

5. Exit *shell mode* by hitting `Backspace` and enter *Pkg mode* by pressing `]`.
6. Precompile the project to install the necessary packages

```julia-repl
pkg> precompile
```

## Usage

### From the Julia REPL

1. Enter the julia repl. On linux machines, this is as simple as running the `julia` command from your terminal emulator.
2. Enter *shell mode* by typing `;` in the repl.
3. `cd` into the AllocationOpt directory. For example

```julia-repl
shell> cd projects/AllocationOpt.jl
```

4. Exit *shell mode* by hitting `Backspace` and enter *Pkg mode* by pressing `]`.
5. Activate the project environment

```julia-repl
pkg> activate .
```

6. Exit *pkg mode* by pressing `Backspace`.
7. Import the `AllocationOpt` package.
```julia-repl
julia> using AllocationOpt
```
8. Call the `optimize_indexer_to_csv!` function with the relevant arguments.
```julia-repl
julia> optimize_indexer_to_csv!("0x001", 2.0, whitelist=nothing, blacklist=["0x010", "0x011"], "/home/user/allocations.csv")
```
The allocations will have been saved to the path specified as a CSV.

### The `optimize_indexer_to_csv!` Function

**Arguments:**
```julia
id::String  # The id of the indexer to optimise
grtgas::Float64  # The gas cost in GRT
whitelist::Union{nothing, Vector{String}}  # A list of subgraph ids to which you want to be able to allocate to. Must be `nothing` if `blacklist` is specified.
blacklist::Union{nothing, Vector{String}}  # A list of subgraph ids to which you don't want to be able to allocate to. Must be `nothing` if `whitelist` is specified.
csv_write_path::String  # The path (including .csv) to the CSV file to which to save the allocations.
```
