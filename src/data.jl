export allocations, signals, stakes

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
            throw(UndefRefError())
        end
    end
    alloc = zeros(length(sgraph_ids))
    for al in indexer_allocations
        ix = nothing
        try
            ix = first(findall(x -> x == al.id, sgraph_ids))
        catch err
            if isa(err, BoundsError)
                throw(UndefRefError())
            end
        end
        alloc[ix] = al.amount
    end

    return alloc
end

function allocations(repo::Repository)
    sgraph_ids = map(x -> x.id, repo.subgraphs)
    alloc = map(x -> allocations(x.id, sgraph_ids, repo), repo.indexers)
    return alloc
end

function signals(repo::Repository)
    return map(x -> x.signal, repo.subgraphs)
end

function stakes(repo::Repository)
    return map(x -> x.stake + x.delegation, repo.indexers)
end
