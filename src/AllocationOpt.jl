# Copyright 2022-, The Graph Foundation
# SPDX-License-Identifier: MIT

module AllocationOpt

using Mocking
using TOML
using TypedTables
using TheGraphData

import SplitApplyCombine as SAC

include("configuration.jl")
include("data.jl")
include("domain.jl")

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
    config = path |> readconfig |> configuredefaults!
    return main(config)
end

function main(config::Dict)
    # Read data
    i, a, s, n = AllocationOpt.read(config)

    # Queried data has not yet been converted to GRT, so
    # if this isn't data that we've queried, correct the
    # types and write the data out to CSVs
    isnothing(config["readdir"]) && write(i, a, s, n, config)

    # Get the indexer stake
    σpinned = pinned(config)
    σ = stake(Val(:indexer), i) - frozen(a, config) - σpinned

    # Get the subgraphs on which we can allocate
    fs = allocatablesubgraphs(s, config)

    # Allocated tokens on filtered subgraphs
    Ω = stake(Val(:subgraph), fs) .+ fudgefactor

    # Signal on filtered subgraphs
    ψ = signal(Val(:subgraph), fs)

    # Signal on all subgraphs
    Ψ = signal(Val(:network), n)

    # New tokens issued over allocation lifetime
    Φ = newtokensissued(n, config)

    return nothing
end

end
