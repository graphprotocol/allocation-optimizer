using Roots

function detach_indexer(repo::Repository, id::AbstractString)::Tuple{Indexer,Repository}
    # Get requested indexer
    i = findfirst(x -> x.id == id, repo.indexers)
    if isnothing(i)
        throw(UnknownIndexerError())
    end
    indexer = repo.indexers[i]

    # Remove indexer from repository
    indexers = filter(x -> x.id != id, repo.indexers)
    frepo = Repository(indexers, repo.subgraphs)
    return indexer, frepo
end

signals(r::Repository) = map(x -> x.signal, r.subgraphs)

function stakes(r::Repository)
    # Loop over subgraphs, getting their names
    subgraphs = map(x -> x.ipfshash, r.subgraphs)

    # Match name to indexer allocations
    allocations = reduce(vcat, map(x -> x.allocations, r.indexers))
    Ω = []
    for subgraph in subgraphs
        subgraph_allocations = filter(x -> x.ipfshash == subgraph, allocations)
        subgraph_amounts = map(x -> x.amount, subgraph_allocations)

        # If no match, then set to 0
        if isempty(subgraph_amounts)
            subgraph_amounts = [0.0]
        end
        stake_on_subgraph = sum(subgraph_amounts)
        append!(Ω, stake_on_subgraph)
    end
    return Ω
end

function solve_dual(Ω, ψ, σ)
    lower_bound = eps(Float64)
    upper_bound = (sum(.√(ψ .* Ω)))^2 / σ
    sol = find_zero(
        x -> sum(max.(0.0, .√(ψ .* Ω / x) .- Ω)) - σ,
        (lower_bound, upper_bound),
        Roots.Brent(),
    )
    return sol
end

solve_primal(Ω, ψ, v) = max.(0.0, .√(ψ .* Ω / v) - Ω)

function optimize(indexer::Indexer, repo::Repository)
    ψ = signals(repo)
    Ω = stakes(repo)
    σ = indexer.stake

    # Solve the dual and use that value to solve the primal
    v = solve_dual(Ω, ψ, σ)
    ω = solve_primal(Ω, ψ, v)

    return ω
end
