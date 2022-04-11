module AllocationOpt
using DataFrames

export optimize_indexer


include("exceptions.jl")
include("graphrepository.jl")
include("data.jl")
include("gascost.jl")
include("optimize.jl")

"""
    optimize_indexer(;id::String, grtgas::Float64, alloc_lifetime::Int64, whitelist::Union{Nothing,Vector{string}}, blacklist::Union{Nothing,Vector{String}})

Optimize the indexer specified by `id`.

# White/Blacklisting

You can either specify `whitelist`, `blacklist`, or neither (setting both to `nothing`). You cannot set both to be non-nothing.

# Return Value

The optimizer will return a Julia DataFrame.
"""
function optimize_indexer(;
    id::String,
    grtgas::Float64,
    alloc_lifetime::Int64,
    whitelist::Union{Nothing,Vector{String}},
    blacklist::Union{Nothing,Vector{String}},
)
    url = "https://api.thegraph.com/subgraphs/name/graphprotocol/graph-network-mainnet"
    repository = snapshot(; url=url, indexer_query=nothing, subgraph_query=nothing)
    network = network_issuance(; url=url, network_id=nothing, network_query=nothing)
    # indexer::Indexer = repository.indexers[findfirst(x -> x.id == id, repository.indexers)]

    alloc, filtered = optimize(id, repository, grtgas, network, alloc_lifetime, whitelist, blacklist)

    # println("""- brief summary -
    #         indexer: $(indexer.id)
    #         available_stake: $(indexer.stake + indexer.delegation)
    #         use gas in grt: $(grtgas) 
    #         use allocation lifetime: $(alloc_lifetime)
    #         number of allocations: $(length(alloc))
    #         indexer_subgraph_rewards: $(sum(indexer_subgraph_rewards(filtered, network, alloc, alloc_lifetime)))
    #         sum_gas_fee: $(sum_gas_fee(alloc, grtgas))
    #         estimated profit: $(estimated_profit(filtered, alloc, grtgas))""")

    df = DataFrame(
        "Subgraph ID" => collect(keys(alloc)), "Allocation in GRT" => collect(values(alloc))
    )
    df[!, "Subgraph Signal"] = map(x -> x.signal, filtered.subgraphs)
    df[!, "Subgraph Indexing Reward"] = subgraph_rewards(filtered, network, alloc_lifetime)
    df[!, "Estimated to Indexer"] = indexer_subgraph_rewards(filtered, network, alloc, alloc_lifetime)
    #TODO: incorporate indexer reward cut to account for reward efficiency, indexing indexer rewards, and indexing delegator rewards 
    # df[!, "Subgraph Indexing Reward to Indexer"] = map(x -> x.signal, filtered.subgraphs)

    return df
end
end
