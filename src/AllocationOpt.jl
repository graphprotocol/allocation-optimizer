module AllocationOpt
using DataFrames
using Formatting

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
#TODO: We might remove this since it is not being used
function optimize_indexer(;
    id::String,
    whitelist::Union{Nothing,Vector{String}},
    blacklist::Union{Nothing,Vector{String}},
)
    
    repository, network = snapshot()

    alloc, filtered = optimize(id, repository, whitelist, blacklist)

    df = DataFrame(
        "Subgraph ID" => collect(keys(alloc)), "Allocation in GRT" => collect(values(alloc))
    )
    df[!, "Subgraph Signal"] = map(x -> x.signal, filtered.subgraphs)
    df[!, "Subgraph Indexing Reward"] = subgraph_rewards(filtered, network, alloc_lifetime)
    df[!, "Estimated to Indexer"] = indexer_subgraph_rewards(
        filtered, network, alloc, alloc_lifetime
    )
    #TODO: incorporate indexer reward cut to account for reward efficiency, indexing indexer rewards, and indexing delegator rewards 
    df[!, "Subgraph Indexing Reward to Indexer"] = map(x -> x.signal, filtered.subgraphs)

    return df
end

"""
optimize_indexer(;id::String, grtgas::Float64, alloc_lifetime::Int64, 
                    whitelist::Union{Nothing,Vector{String}}, blacklist::Union{Nothing,Vector{String}},
                    alloc_lifetime_threshold::Int64, preference_ratio::Float64)::DataFrame

# Arguments
- `id::String`: indexer address
- `grtgas::Float64`: the price you would want pay for each allocation transaction (grtgas * 1 for open, grtgas * 1 for close, grtgas * 0.3 for claim). Higher setting will lead to smaller set of allocations.
- `alloc_lifetime::Int64`: the frequency to renew a specific allocation. Smaller alloction lifetime allows less time to accumulate indexing rewards, thus lead to smaller set of allocations.
- `whitelist::Union{Nothing,Vector{String}}`: when set, optimizer will only consider these subgraphs (Qm...), and you cannot set blacklist.
- `blacklist::Union{Nothing,Vector{String}}`: when set, optimizer will not consider these subgraphs (Qm...), and you cannot set whitelist.
- `alloc_lifetime_threshold::Int64`: determine which current allocations should be re-considered during optimization. With higher threshold, the optimizer blacklist more subgrpahs. If you set this to 0, all current allocations will be considered in optimization.
- `preference_ratio::Float64`: the ratio between reallocating or keep open the current allocations. If you set to 1.0, optimizer simply takes the higher reward. If you set this to >1.0, you prefer to reallocate, if you set this to <1.0, you prefer to keep current allocation until it expires. 
"""
function optimize_indexer(;
    id::String,
    grtgas::Float64,
    alloc_lifetime::Int64,
    whitelist::Union{Nothing,Vector{String}},
    blacklist::Union{Nothing,Vector{String}},
    alloc_lifetime_threshold::Int64,
    preference_ratio::Float64,
)
    if (alloc_lifetime_threshold <= 0)
        throw("alloc_lifetime_threshold minimum value is 1, please change it.")
    end

    # Fetch data
    repository, network = snapshot()
    indexer::Indexer = repository.indexers[findfirst(x -> x.id == id, repository.indexers)]

    # Do not consider any allocations younger than alloc_lifetime_threshold 
    young_list = filter_young_allocations(id, repository, alloc_lifetime_threshold, network)
    if isnothing(blacklist)
        blacklist = young_list
    else
        blacklist = append!(blacklist, young_list)
    end

    # Optimize and create summary
    alloc, filtered = optimize(
        id,
        repository,
        grtgas,
        network,
        alloc_lifetime,
        preference_ratio,
        whitelist,
        blacklist,
    )
    alloc_list = filter(
        a -> a.amount != 0,
        map(
            alloc_id -> Allocation(alloc_id, alloc[alloc_id], network.current_epoch),
            collect(keys(alloc)),
        ),
    )
    actions = create_actions(
        id,
        filtered,
        repository,
        network,
        alloc_list,
        alloc_lifetime,
        grtgas,
        preference_ratio,
        young_list,
    )

    df = DataFrame(
        "Subgraph ID" => map(a -> a.id, alloc_list),
        "Allocation in GRT" => map(a -> a.amount, alloc_list),
    )
    df[!, "Subgraph Signal"] = map(
        x -> x.signal, filter(sg -> sg.id in map(a -> a.id, alloc_list), filtered.subgraphs)
    )
    df[!, "Indexing Reward"] = indexer_subgraph_rewards(
        filtered, network, alloc_list, alloc_lifetime
    )
    # Add alloc rows for close actions? Currently only have allocations that want to Open or Reallocate
    df[!, "Action"] = map(
        a -> a in actions[2] ? "Open" : (a in actions[3] ? "Reallocate" : "Do not open"),
        alloc_list,
    )

    print_summary(indexer, df, alloc_list, actions[1], alloc_lifetime)

    return df
end

function print_summary(indexer, df, alloc_list, close_actions, alloc_lifetime)
    println(
        """- brief summary -
        indexer: $(indexer.id) , available_stake: $(indexer.stake + indexer.delegation)
        use allocation lifetime: $(alloc_lifetime), number of allocations: $(length(alloc_list))
        dataframe: $(df)
        """,
    )
    for a in alloc_list
        println(
            "graph indexer rules set $(a.id) decisionBasis always allocationAmount $(format(a.amount))",
        )
    end
    for a in close_actions
        println("graph indexer rules stop ", a.id)
    end
end

end
