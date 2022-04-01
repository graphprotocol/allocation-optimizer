using Roots

export optimize

function optimize(optimize_id::String, repository::Repository, whitelist, blacklist)
    if !isnothing(whitelist) && !isnothing(blacklist)
        throw(ArgumentError("whitelist and blacklist cannot both be specified"))
    end

    function dual(Ω, ψ, σ)
        lower_bound = 1e-25
        upper_bound = (sum(.√(ψ .* Ω)))^2 / σ
        sol = find_zero(
            x -> sum(max.(0.0, .√(ψ .* Ω / x) .- Ω)) - σ,
            (lower_bound, upper_bound),
            Roots.Brent(),
        )
        return sol
    end

    other_indexers = blacklist_to_whitelist(String[optimize_id], repository.indexers)
    if !isnothing(blacklist)
        whitelist = blacklist_to_whitelist(blacklist, repository.subgraphs)
    end
    if isnothing(whitelist)
        whitelist = blacklist_to_whitelist(String[], repository.subgraphs)
    end
    whitelist_with_indexer = vcat(other_indexers, whitelist)

    indexer = first(filter(x -> x.id == optimize_id, repository.indexers))
    σ = indexer.stake + indexer.delegation
    filtered_repo = whitelist_repo(whitelist_with_indexer, repository)
    ψ = signals(filtered_repo)
    Ω = dropdims(sum(allocations(filtered_repo); dims=1); dims=1)
    v = dual(Ω, ψ, σ)
    ω = max.(0.0, .√(ψ .* Ω / v) - Ω)
    sgraph_ids = map(x -> x.id, filtered_repo.subgraphs)
    alloc = Dict(sgraph_ids .=> ω)

    # TODO: Hope's gas algorithm

    return alloc
end
