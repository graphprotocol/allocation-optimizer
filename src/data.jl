export allocation_amounts,
    signals, stakes, indexer, young_allocations, allocations_by_indexer

function allocations_by_indexer(id::String, repo::Repository)
    try
        return first(filter(x -> x.id == id, repo.indexers)).allocations
    catch err
        if isa(err, BoundsError)
            throw(UnknownIndexerError(id))
        end
    end
end

function allocation_amounts(id::String, repo::Repository)
    sgraph_ids = map(x -> x.id, repo.subgraphs)
    return allocation_amounts(id, sgraph_ids, repo)
end

function allocation_amounts(id::String, sgraph_ids::Vector{String}, repo::Repository)
    indexer_allocations = allocations_by_indexer(id, repo)
    alloc = zeros(length(sgraph_ids))
    for al in indexer_allocations
        ix = findfirst(x -> x == al.id, sgraph_ids)
        if (isnothing(ix))
            throw(UnknownSubgraphError(al.id))
        end
        alloc[ix] = al.amount
    end

    return alloc
end

function allocation_amounts(repo::Repository)
    sgraph_ids = map(x -> x.id, repo.subgraphs)
    alloc = map(x -> allocation_amounts(x.id, sgraph_ids, repo), repo.indexers)
    mat = reduce(vcat, transpose.(alloc))
    return mat
end

function allocation_amounts(repo::Repository, subg_ids::Vector{String})
    return map(subg_id -> allocation_amounts(repo, subg_id), subg_ids)
end

function allocation_amounts(repo::Repository, subg_id::String)
    allocAmount = 0
    for indexer in repo.indexers
        allos = filter(
            alloc -> alloc.id == subg_id, allocations_by_indexer(indexer.id, repo)
        )
        allocAmount += sum(map(x -> x.amount, allos))
    end
    return allocAmount
end

function allocation_amounts(id::String, repo::Repository, sgraph_id::String)
    indexer_allocations = allocations_by_indexer(id, repo)
    alloc = first(filter(x -> x.id == sgraph_id, indexer_allocations))
    if (isnothing(alloc))
        throw(UnknownSubgraphError(alloc))
    end
    return alloc
end

function young_allocations(
    id::String, repo::Repository, alloc_lifetime::Int, network::GraphNetworkParameters
)
    young_allocations = filter(
        ix -> ix.created_at_epoch + alloc_lifetime > network.current_epoch, allocations_by_indexer(id, repo)
    )

    return map(x -> x.id, young_allocations)
end

function signals(repo::Repository)
    return map(x -> x.signal, repo.subgraphs)
end

function signals(repo::Repository, subg_id::String)
    return repo.subgraphs[findfirst(x -> x.id == subg_id, repo.subgraphs)].signal
end

function signal_shares(repo::Repository, network::GraphNetworkParameters)
    total_signalled = network.total_tokens_signalled
    return map(x -> x.signal / total_signalled, repo.subgraphs)
end

function signal_shares(repo::Repository, network::GraphNetworkParameters, alloc_list::Dict{String,Float64})
    total_signalled = network.total_tokens_signalled
    ids = collect(keys(alloc_list))
    return map(x -> x.signal / total_signalled, filter(x -> x.id in ids, repo.subgraphs))
end

function signal_shares(repo::Repository, network::GraphNetworkParameters, alloc_list::Vector{Allocation})
    total_signalled = network.total_tokens_signalled
    ids = map(a -> a.id, alloc_list)
    return map(x -> x.signal / total_signalled, filter(x -> x.id in ids, repo.subgraphs))
end

function stakes(repo::Repository, indexer_id::String)
    indexer = repo.indexers[findfirst(x -> x.id == indexer_id, repo.indexers)]
    return indexer.stake + indexer.delegation
end

function stakes(repo::Repository)
    return map(x -> x.stake + x.delegation, repo.indexers)
end

function whitelist_repo(ids::Vector{String}, repo::Repository)
    updated_indexers = filter(x -> x.id in ids, repo.indexers)
    updated_subgraphs = filter(x -> x.id in ids, repo.subgraphs)
    updated_allocations = map(
        x -> filter(y -> y.id in ids, x.allocations), updated_indexers
    )

    new_indexers = map(
        (x, y) -> Indexer(x.id, x.delegation, x.stake, y),
        updated_indexers,
        updated_allocations,
    )

    return Repository(new_indexers, updated_subgraphs)
end

function blacklist_to_whitelist(ids::Vector{String}, data)
    all_ids = map(x -> x.id, data)
    return filter(x -> !(x in ids), all_ids)
end

function indexer(id::String, repository::Repository)
    return first(filter(x -> x.id == id, repository.indexers))
end

function subgraph_allocations(repo::Repository)
    return dropdims(sum(allocation_amounts(repo); dims=1); dims=1)
end

function subgraph_allocations(repo::Repository, alloc_list::Vector{String})
    return allocation_amounts(repo, alloc_list)
end
