module AllocationOpt
using DataFrames

export optimize_indexer


include("exceptions.jl")
include("graphrepository.jl")
include("data.jl")
include("costbenefit.jl")
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

    alloc, filtered = optimize(id, repository, grtgas, network, alloc_lifetime, whitelist, blacklist)

    df = DataFrame(
        "Subgraph ID" => collect(keys(alloc)), "Allocation in GRT" => collect(values(alloc))
    )
    df[!, "Subgraph Signal"] = map(x -> x.signal, filtered.subgraphs)
    df[!, "Subgraph Indexing Reward"] = subgraph_rewards(filtered, network, alloc_lifetime)
    df[!, "Estimated to Indexer"] = indexer_subgraph_rewards(filtered, network, alloc, alloc_lifetime)
    #TODO: incorporate indexer reward cut to account for reward efficiency, indexing indexer rewards, and indexing delegator rewards 
    df[!, "Subgraph Indexing Reward to Indexer"] = map(x -> x.signal, filtered.subgraphs)

    return df
end


function optimize_indexer(;
    id::String,
    grtgas::Float64,
    alloc_lifetime::Int64,
    whitelist::Union{Nothing,Vector{String}},
    blacklist::Union{Nothing,Vector{String}},
    alloc_lifetime_threshold::Int64,
    preference_threshold::Float64,
)
    if (alloc_lifetime_threshold <= 0)
        optimize_indexer(; id, grtgas, alloc_lifetime, whitelist, blacklist)
    end

    url = "https://api.thegraph.com/subgraphs/name/graphprotocol/graph-network-mainnet"
    repository = snapshot(; url=url, indexer_query=nothing, subgraph_query=nothing)
    network = network_issuance(; url=url, network_id=nothing, network_query=nothing)
    indexer::Indexer = repository.indexers[findfirst(x -> x.id == id, repository.indexers)]

    young_list = filter_young_allocations(id, repository, alloc_lifetime_threshold, network)

    if isnothing(blacklist)
        blacklist = young_list
    else
        append!(blacklist, young_list)
    end

    alloc, filtered = optimize(id, repository, grtgas, network, alloc_lifetime, whitelist, blacklist)
    alloc_list = filter(a -> a.amount != 0, map(alloc_id -> Allocation(alloc_id, alloc[alloc_id], network.current_epoch), collect(keys(alloc))))
    actions = create_actions(id, filtered, repository, network, alloc_list, alloc_lifetime, grtgas, preference_threshold)

    # if there are close actions, the optimized result should be updated - run optimizer again here as we put subgraphs to close into blacklist
    blacklist = append!(map(action -> action.id, actions[1]), blacklist)

    # run a second time for the updated blacklist
    alloc, filtered = optimize(id, repository, grtgas, network, alloc_lifetime, whitelist, blacklist)
    alloc_list = filter(a -> a.amount != 0, map(alloc_id -> Allocation(alloc_id, alloc[alloc_id], network.current_epoch), collect(keys(alloc))))
    actions = create_actions(id, filtered, repository, network, alloc_list, alloc_lifetime, grtgas, preference_threshold)
   
    # println("""- brief summary -
    #         indexer: $(indexer.id) , available_stake: $(indexer.stake + indexer.delegation)
    #         use gas in grt: $(grtgas) , use allocation lifetime: $(alloc_lifetime), number of allocations: $(length(filter(a -> a > 0.0, collect(values(alloc)))))
    #         indexer_subgraph_rewards: $(sum(indexer_subgraph_rewards(filtered, network, alloc, alloc_lifetime)))
    #         actions: $(actions)
    #         """)

    df = DataFrame(
        "Subgraph ID" => map(a -> a.id, alloc_list), "Allocation in GRT" => map(a -> a.amount, alloc_list)
    )
    df[!, "Subgraph Signal"] = map(x -> x.signal, filtered.subgraphs)
    df[!, "Subgraph Indexing Reward"] = subgraph_rewards(filtered, network, alloc_lifetime)
    df[!, "Estimated Profit"] = estimated_profit(filtered, alloc_list, grtgas, network, alloc_lifetime)
    # add rows for close actions. Currently only have Open or Reallocate
    df[!, "Action"] = map(a -> a in actions[2] ? "Open" : "Reallocate" , alloc_list)
    return df
end
end
