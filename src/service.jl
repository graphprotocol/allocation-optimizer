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

function projectsimplex(x::AbstractVector{T}, z) where {T<:Real}
    n = length(x)
    μ = sort(x; rev=true)
    ρ = maximum((1:n)[μ - (cumsum(μ) .- z) ./ (1:n) .> zero(T)])
    θ = (sum(μ[1:ρ]) - z) / ρ
    w = max.(x .- θ, zero(T))
    return w
end

projectrange(low, high, x::T) where {T<:Real} = max(min(x, one(T) * high), one(T) * low)

shrink(z::T, α) where {T<:Real} = sign(z) .* max(abs(z) - α, zero(T))

∇f(ω::T, ψ, Ω, μ, p) where {T<:Real} = -((ψ * Ω) / (ω + Ω + eps(T))^2) - (μ * p)

# removed (ω .+ _) from the numerator to only include Ω, also removed minimum bound of 1: maximum(_, 1)
compute_λ(ω, ψ, Ω) = minimum(nonzero(((Ω) .^ 3) ./ (2 .* ψ)))

nonzero(v::Vector{<:Real}) = v[findall(v .!= 0.0)]
