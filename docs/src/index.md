```@meta
CurrentModule = AllocationOpt
```

# AllocationOpt

Documentation for [AllocationOpt](https://github.com/graphprotocol/AllocationOpt.jl).

AllocationOpt is a library for optimising how an indexer should allocate its stake in [The Graph Protocol](https://thegraph.com/en/).

**Important:** You must run this on a computer that supports 64-bit operations. 32-bit doesn't have enough precision to solve the optimisation problem.

## Installation

1. Clone the github repository.

```bash
$ git clone git@github.com:graphprotocol/AllocationOpt.jl.git
```

1. Enter the julia repl. On linux machines, this is as simple as running the `julia` command from your terminal emulator. For MacOS, you'll need to add Julia to your path. See this [StackOverflow post](https://stackoverflow.com/questions/72123620/permission-denied-when-i-am-trying-to-add-julia-to-path-in-macos/72308646#72308646) if you're having issues.
2. Add this package by adding the github url. First, enter package mode `]`. Then, type `add https://github.com/graphprotocol/AllocationOpt.jl`. You'll also want to add the [Comonicon package](https://github.com/comonicon/Comonicon.jl).

```julia-repl
pkg> add https://github.com/graphprotocol/AllocationOpt.jl/
pkg> add Comonicon
```

```@autodocs
Modules = [AllocationOpt]
```
