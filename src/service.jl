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

function stakes(r::Repository)
    # Loop over subgraphs, getting their names
    subgraphs = ipfshash.(r.subgraphs)

    # Match name to indexer allocations
    ω = reduce(vcat, allocation.(r.indexers))
    Ω = []
    for subgraph in subgraphs
        subgraph_allocations = filter(x -> x.ipfshash == subgraph, ω)
        subgraph_amounts = allocated_stake.(subgraph_allocations)

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
    ψ = signal.(repo.subgraphs)
    Ω = stakes(repo)
    σ = indexer.stake

    # Solve the dual and use that value to solve the primal
    v = solve_dual(Ω, ψ, σ)
    ω = solve_primal(Ω, ψ, v)

    return ω
end

function optimize(
    indexer::Indexer,
    repo::Repository,
    max_allocations::Integer,
    min_allocation_amounts::Float64,
)
    ψ = signal.(repo.subgraphs)
    Ω = stakes(repo)
    σ = indexer.stake

    # Parameters
    λ = 0

    # Initialise
    ω = zeros(length(ψ))
    p = zeros(length(ψ))

    # Stop conditions: added an allocation < minimum allocation amounts, or when nonzero allocations \geq max_allocaitons
    while !stop_conditions(ω, min_allocation_amounts, max_allocations)
        z = ω
        for _ in range(100)
            ξ = project(z, σ)
            y = shrink(2ξ - z - λ * (-ψ * ω) / (ω + Ω)^2 - p, α)
            z = z + y - ξ
        end
        ω = ξ
        p = max(min(p + 1 / μ * (-ψ * ω) / (ω + Ω)^2, 1), -1)
    end
end

shrink(z, α) = sign(z) .* map(x -> max(0, x), abs(z) - α)

function project(x, σ)
    ξ = x / σ
    ζ = sort(ξ; rev=true)
    ρ = maximum(
        map(
            x -> x[1] + (1 / x[2]) * (1 - sum(ζ[1:x[2]])) > 0 ? x[2] : typemin(Int64),
            enumerate(ζ),
        ),
    )
    λ = (1 / ρ)(1 - sum(ζ[1:ρ]))
    z = σ * map(x -> max(0, x + λ), ξ)
    return z
end

function stop_conditions(ω, minimum_allocation_amounts, max_allocations)
    (min(ω) < minimum_allocation_amounts) | sum(map(x -> !iszero(x) ? 1 : 0 , ω)) > max_allocations
end