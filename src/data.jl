export allocations, signals, stakes, indexer

function allocations(id::String, repo::Repository)
    sgraph_ids = map(x -> x.id, repo.subgraphs)
    return allocations(id, sgraph_ids, repo)
end

function allocations(id::String, sgraph_ids::Vector{String}, repo::Repository)
    indexer_allocations = nothing
    try
        indexer_allocations = first(filter(x -> x.id == id, repo.indexers)).allocations
    catch err
        if isa(err, BoundsError)
            throw(UnknownIndexerError(id))
        end
    end
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

function allocations(repo::Repository)
    sgraph_ids = map(x -> x.id, repo.subgraphs)
    alloc = map(x -> allocations(x.id, sgraph_ids, repo), repo.indexers)
    mat = reduce(vcat, transpose.(alloc))
    return mat
end

function allocations(repo::Repository, subg_id::String)
    allocAmount = 0
    for indexer in repo.indexers
        allocAmount += first(filter(alloc -> alloc.id == subg_id, first(filter(x -> x.id == indexer.id, repo.indexers)).allocations)).amount
    end
    return allocAmount
end

function signals(repo::Repository)
    return map(x -> x.signal, repo.subgraphs)
end

function signals(repo::Repository, subg_id::String)
    return repo.subgraphs[findfirst(x -> x.id == subg_id, repo.subgraphs)].signal
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

indexer(id::String, repository::Repository) = first(filter(x -> x.id == id, repository.indexers))

subgraph_allocations(repo::Repository) = dropdims(sum(allocations(repo); dims=1); dims=1)
