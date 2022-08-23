using Roots
using LinearAlgebra
using Distributed
using ProgressMeter
using SharedArrays

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
    Ω = Float64[]
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

function optimize(Ω::AbstractVector{T}, ψ::AbstractVector{T}, σ::T) where {T<:Real}
    # Add 1 to Ω to prevent degenerate cases
    Ω .+= 1
    # Solve the dual and use that value to solve the primal
    v = solve_dual(Ω, ψ, σ)
    ω = solve_primal(Ω, ψ, v)

    return ω
end

function optimize(
    Ω::AbstractVector{T},
    ψ::AbstractVector{T},
    σ::T,
    max_allocations::Int,
    filter_fn::Function,
) where {T<:Real}
    # Add 1 to Ω to prevent degenerate cases
    Ωadj = Ω .+ 1
    η = 1e5
    Δη = 1.001
    patience = 1e4
    tol = 1e-10
    # do projected gradient descent for projection onto the k-sparse until convergence
    ωs = pmap(1:max_allocations) do k
        println("Optimising for $k allocations.")
        ω = pgd(ψ, Ωadj, k, σ, η, Δη, patience, tol)
        println("$k allocations optimised.")
        return ω
    end
    ωs = reduce(hcat, ωs)

    # Choose the best ω ∈ ωs
    ω = filter_fn(ωs, ψ, Ω)

    return ω
end

function pgd(
    ψ::AbstractVector{<:Real},
    Ω::AbstractVector{<:Real},
    k::Int,
    σ::Real,
    η::Real,
    Δη::Real,
    patience::Real,
    tol::Real,
)
    xold = -1 .* ones(length(Ω))
    xnew = ones(length(Ω))
    x = zeros(length(Ω))

    # Run pgd_step until convergence
    # TODO: Patience so that we don't end up in a while true loop
    j = 0
    while !isapprox(x, xnew; rtol=tol)
        # (re)set x to xnew
        x = xnew
        xnew = pgd_step(x, ψ, Ω, k, σ, η)
        if norm(xnew - x) ≥ norm(x - xold)
            # Learning rate is too high, so we've diverged.
            η *= 1 / Δη
            j = 0
        else
            j += 1
            if j > patience
                η *= Δη
            end
        end
        xold = x
    end
    return xnew
end

function pgd_step(
    x::AbstractVector{<:Real},
    ψ::AbstractVector{<:Real},
    Ω::AbstractVector{<:Real},
    k::Int,
    σ::Real,
    η::Real,
)
    z = x .- η * ∇f.(x, ψ, Ω)
    x₁ = gssp(z, k, σ)
    return x₁
end

# http://proceedings.mlr.press/v28/kyrillidis13.pdf
function gssp(x::AbstractVector{<:Real}, k::Int, σ::Real)
    # Get length(x)-k smallest indices of x
    biggest_ixs = partialsortperm(x, 1:k; rev=true)
    # Set all other indices of x to 0 and project result onto simplex
    v = x[biggest_ixs]
    vproj = projectsimplex(v, σ)
    w = zeros(eltype(vproj), length(x))
    w[biggest_ixs] .= vproj
    return w
end

function projectsimplex(x::AbstractVector{T}, z) where {T<:Real}
    n = length(x)
    μ = sort(x; rev=true)
    ρ = maximum((1:n)[μ - (cumsum(μ) .- z) ./ (1:n) .> zero(T)])
    θ = (sum(μ[1:ρ]) - z) / ρ
    w = max.(x .- θ, zero(T))
    return w
end

∇f(x::T, ψ, Ω) where {T<:Real} = -((ψ * Ω) / (x + Ω)^2)

function discount(
    Ω::AbstractVector{T}, ψ::AbstractVector{T}, σ::T, τ::AbstractFloat
) where {T<:Real}
    Ω0 = zeros(length(Ω))
    Ωstar = optimize(Ω0, ψ, σ)
    Ωprime = projectsimplex(τ * Ωstar + (1 - τ) * Ω, σ)
    return Ωprime
end

function discountΩ(fullrepo::Repository, repo::Repository, τ::Real)
    return discountΩ(fullrepo, repo.subgraphs, τ)
end

function discountΩ(
    fullrepo::Repository, subgraphs::AbstractVector{SubgraphDeployment}, τ::Real
)
    Ωfull = stakes(fullrepo)
    ψfull = signal.(fullrepo.subgraphs)
    σfull = sum(Ωfull)
    Ωprime = discount(Ωfull, ψfull, σfull, τ)
    ψids = id.(subgraphs)
    ψfullids = id.(fullrepo.subgraphs)
    return Ωprime[findall(x -> x in ψids, ψfullids)]
end

function tokens_issued_over_lifetime(
    network::GraphNetworkParameters, allocation_lifetime::Integer
)
    return network.principle_supply *
           network.issuance_rate_per_block^(network.block_per_epoch * allocation_lifetime) -
           network.principle_supply
end

function profit(
    network::GraphNetworkParameters,
    gas::Float64,
    allocation_lifetime::Integer,
    ω::AbstractVector{T},
    ψ::AbstractVector{T},
    Ω::AbstractVector{T},
) where {T<:Real}
    Φ = tokens_issued_over_lifetime(network, allocation_lifetime)
    gascost = gasperallocation(gas) * length(ω[findall(ω .!= 0.0)])
    indexing_rewards = f(ψ, Ω, ω, Φ, network.total_tokens_signalled)
    return indexing_rewards - gascost
end

function profitᵢ(
    network::GraphNetworkParameters,
    gas::Float64,
    allocation_lifetime::Integer,
    ω::AbstractVector{T},
    ψ::AbstractVector{T},
    Ω::AbstractVector{T},
) where {T<:Real}
    Φ = tokens_issued_over_lifetime(network, allocation_lifetime)
    gascost = zeros(length(ω))
    gascost[findall(ω .!= 0.0)] .= gasperallocation(gas)
    indexing_rewards = fᵢ.(ψ, Ω, ω, Φ, network.total_tokens_signalled)
    return indexing_rewards .- gascost
end

function gasperallocation(gas)
    # Assume cost for an allocation's life require open and close
    open_multiplier = 1.0
    close_multiplier = 1.0
    return open_multiplier * gas + close_multiplier * gas
end

function f(
    ψ::AbstractVector{T}, Ω::AbstractVector{T}, ω::AbstractVector{T}, Φ::T, Ψ::T
) where {T<:Real}
    subgraph_rewards = Φ .* ψ ./ Ψ
    indexing_rewards = sum(subgraph_rewards .* ω ./ (Ω .+ ω))
    return indexing_rewards
end

function fᵢ(ψ::T, Ω::T, ω::T, Φ::T, Ψ::T) where {T<:Real}
    subgraph_rewards = Φ * ψ / Ψ
    return subgraph_rewards * ω / (Ω + ω)
end

# Rough estimate with allocated time of 365 epochs in a year 
function annual_percentage_return(profit, principle, period_duration)
    return (profit / principle) / period_duration * 365
end

function aprᵢ(
    ψ::T, Ω::T, ω::T, Φ::T, Ψ::T, gas::Float64, allocation_lifetime::Integer
) where {T<:Real}
    if (iszero(ω))
        return ω
    end
    subgraph_rewards = Φ * ψ / Ψ
    indexing_rewards = subgraph_rewards * ω / (Ω + ω)
    profit = indexing_rewards - gasperallocation(gas)

    return annual_percentage_return(profit, ω, allocation_lifetime)
end

function apr(
    network::GraphNetworkParameters,
    gas::Float64,
    allocation_lifetime::Integer,
    ω::AbstractVector{T},
    ψ::AbstractVector{T},
    Ω::AbstractVector{T},
    ipfshashes::Vector{String},
) where {T<:Real}
    Φ = tokens_issued_over_lifetime(network, allocation_lifetime)

    apr = aprᵢ.(ψ, Ω, ω, Φ, network.total_tokens_signalled, gas, allocation_lifetime)
    profit = profitᵢ(network, gas, allocation_lifetime, ω, ψ, Ω)
    allocation_aprs = Dict(
        k => (v, p, a) for (k, v, p, a) in zip(ipfshashes, ω, profit, apr) if v > 0.0
    )
    return allocation_aprs
end
