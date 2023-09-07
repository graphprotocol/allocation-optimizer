# Copyright 2022-, The Graph Foundation
# SPDX-License-Identifier: MIT

module AllocationOpt

using JSON
using LinearAlgebra
using Mocking
using Roots
using SemioticOpt
using TheGraphData
using TOML
using TypedTables
using Formatting

import SplitApplyCombine as SAC

include("configuration.jl")
include("data.jl")
include("domain.jl")
include("opt.jl")
include("reporting.jl")

const fudgefactor = 1.0  # prevents divide by zero

function julia_main()::Cint
    try
        main(ARGS)
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
    return 0 # if things finished successfully
end

main(args::Vector{String}) = main(first(args))

function main(path::AbstractString)
    # Read config and set defaults
    config = path |> readconfig |> configuredefaults! |> formatconfig!
    return main(config)
end

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

    # Get indices of subgraphs that can get indexing rewards
    rixs = deniedzeroixs(fs)

    # Get max number of allocations
    K = min(config["max_allocations"], length(rixs))

    # Get gas cost in GRT
    g = config["gas"]

    # Get optimal values
    config["verbose"] && @info "Optimizing"
    xs, nonzeros, profitmatrix = optimize(Ω, ψ, σ, K, Φ, Ψ, g, rixs, config)

    # Add the pinned stake back in
    xs .= xs .+ pinnedvec

    # Ensure that the indexer stake is not exceeded
    σmax = σ + σpinned
    for x in sum(xs; dims=1)
        isnan(x) ||
            x ≤ σmax ||
            error("Tried to allocate more stake than is available by $(x - σmax)")
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

end
