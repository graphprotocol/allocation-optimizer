module AllocationOpt
using CSV
using DataFrames

export optimize_indexer_to_csv!


include("exceptions.jl")
include("graphrepository.jl")
include("data.jl")
include("gascost.jl")
include("optimize.jl")

function optimize_indexer_to_csv!(;
    id::String,
    gas::Float64,
    whitelist::Union{Nothing,Vector{String}},
    blacklist::Union{Nothing,Vector{String}},
    csv_write_path::String,
)
    url = "https://api.thegraph.com/subgraphs/name/graphprotocol/graph-network-mainnet"
    repository = snapshot(; url=url, indexer_query=nothing, subgraph_query=nothing)

    alloc, filtered = optimize(id, repository, whitelist, blacklist)

    df = DataFrame(
        "Subgraph ID" => collect(keys(alloc)), "Allocation in GRT" => collect(values(alloc))
    )
    df[!, "Subgraph Signal"] = map(x -> x.signal, filtered.subgraphs)
    return CSV.write(csv_write_path, df)
end
end
