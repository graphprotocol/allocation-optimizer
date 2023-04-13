# Calling From Another Language

It's possible to call the Allocation Optimizer from another language.
There are already some solutions out there that do this.
In general, if you're going to take this approach, we assume that you know what you're doing.
We won't hold your hand through the process as we don't want to officially support a multitude of different languages.
Instead, we'll point you to resources you can use for various languages.

!!! warning
    We don't recommend you use this approach, as you may have to delay integrating bugfixes and new features while you are figuring out how to integrate the new code.
    People using the mainline routes will always be able to more quickly access the updates we push.
    We especially don't recommend this route if you're not a developer.
    We will not support bugs that arise from integrating the tool into third-party scripts.
    
* [C/C++](https://docs.julialang.org/en/v1/manual/embedding/)
* [Python](https://docs.juliahub.com/PythonCall/WdXsa/0.9.12/)
* [Rust](https://docs.rs/jlrs/latest/jlrs/)

## Under The Hood

Before we let you go, we'll explain at a high-level the main function.
Roughly speaking, we can break down this problem into the following steps.

1. Read the data, where from the network subgraph or from local CSVs. The currency used is GRT.
1. Filter the data based on the whitelist, blacklist, pinnedlist, and frozenlist
1. Get the values we care about for the indexing rewards
  * `σ` - The indexer's stake
  * `Ω` - A vector of floats containing the sum of the allocations of all other indexers on each subgraph in our data
  * `ψ` - A vector of floats representing the signal on each subgraph in our data.
  * `Ψ` - A float representing the total signal in the network
  * `K` - The maximum number of new allocations
  * `g` - The gas cost in GRT
1. Get the optimal allocation vectors for each `k ∈ 1,...,K`
1. Sort these by their profit
1. Report information about the most profitable vectors.

The full code for the main function with comments follows.

```julia
function main(config::Dict)
    # Read data
    i, a, s, n = AllocationOpt.read(config)

    # Write the data if it was queried rather than read from file
    isnothing(config["readdir"]) && write(i, a, s, n, config)

    # Get the subgraphs on which we can allocate
    fs = allocatablesubgraphs(s, config)

    # Get the indexer stake
    pinnedvec = pinned(fs, config)
    σpinned = pinnedvec |> sum
    σ = availablestake(Val(:indexer), i) - frozen(a, config) - σpinned
    @assert σ > 0 "No stake available to allocate with the configured frozenlist and pinnedlist"

    # Allocated tokens on filtered subgraphs
    Ω = stake(Val(:subgraph), fs) .+ fudgefactor

    # Signal on filtered subgraphs
    ψ = signal(Val(:subgraph), fs)

    # Signal on all subgraphs
    Ψ = signal(Val(:network), n)

    # New tokens issued over allocation lifetime
    Φ = newtokenissuance(n, config)

    # Get max number of allocations
    K = min(config["max_allocations"], length(fs))

    # Get gas cost in GRT
    g = config["gas"]

    # Get optimal values
    config["verbose"] && @info "Optimizing"
    xs, nonzeros, profitmatrix = optimize(Ω, ψ, σ, K, Φ, Ψ, g)

    # Add the pinned stake back in
    xs .= xs .+ pinnedvec

    # Ensure that the indexer stake is not exceeded
    σmax = σ + σpinned
    for x in sum(xs; dims=1)
        x ≤ σmax || error("Tried to allocate more stake than is available")
    end

    # Write the result values
    # Group by unique number of nonzeros
    groupixs = groupunique(nonzeros)
    groupixs = Dict(keys(groupixs) .=> values(groupixs))

    config["verbose"] && @info "Writing results report"
    # For each set of nonzeros, find max profit (should be the same other than rounding)
    popts = bestprofitpernz.(values(groupixs), Ref(profitmatrix)) |> sortprofits!
    nreport = min(config["num_reported_options"], length(popts))

    # Create JSON string
    strategies =
        strategydict.(popts[1:nreport], Ref(xs), Ref(nonzeros), Ref(fs), Ref(profitmatrix))
    reportdata = JSON.json(Dict("strategies" => strategies))

    # Write JSON string to file
    writejson(reportdata, config)

    config["verbose"] && @info "Executing best strategy"
    # Use config for using actionqueue or rules with the top profit batch
    ix = first(popts)[:index]
    execute(a, ix, fs, xs, profitmatrix, config)

    return nothing
end
```

For details on any of the specific functions called, look at the [API Reference](@ref).
