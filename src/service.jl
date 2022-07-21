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
    Ω::AbstractVector{T}, ψ::AbstractVector{T}, σ::Real, max_allocations::Int
) where {T<:Real}
    max_allocations = min(max_allocations, length(Ω))
    # Add 1 to Ω to prevent degenerate cases
    Ω .+= 1
    η = 1e8
    ηdown = 0.9
    ωs = SharedMatrix{T}(max_allocations, length(Ω))
    # do projected gradient descent for projection onto the k-sparse until convergence
    @showprogress @distributed for k in 1:max_allocations
        ωs[k, :] = pgd(ψ, Ω, k, σ, η, ηdown)
    end
    return ωs[max_allocations, :]
end

function pgd(
    ψ::AbstractVector{<:Real},
    Ω::AbstractVector{<:Real},
    k::Int,
    σ::Real,
    η::Real,
    ηdown::Real,
)
    xold = -1 .* ones(length(Ω))
    xnew = ones(length(Ω))
    x = zeros(length(Ω))

    # Run pgd_step until convergence
    tol = 1e-3
    i = 0
    j = 0
    patience = 1e4
    while !isapprox(x, xnew; atol=tol)
        # (re)set x to xnew
        x = xnew
        xnew = pgd_step(x, ψ, Ω, k, σ, η)
        if norm(xnew - x) ≥ norm(x - xold)
            # Learning rate is too high, so we've diverged.
            η *= 1 / 1.001
            j = 0
        else
            j += 1
            if j > patience
                η *= 1.001
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

# NOTE: function not used
projectrange(low, high, x::T) where {T<:Real} = max(min(x, one(T) * high), one(T) * low)

# NOTE: function not used
shrink(z::T, α) where {T<:Real} = sign(z) .* max(abs(z) - α, zero(T))

# NOTE: function not used
∇f(ω::T, ψ, Ω, μ, p) where {T<:Real} = -((ψ * Ω) / (ω + Ω + eps(T))^2) - (μ * p)

∇f(x::T, ψ, Ω) where {T<:Real} = -((ψ * Ω) / (x + Ω)^2)

# NOTE: function not used
# removed (ω .+ _) from the numerator to only include Ω, also removed minimum bound of 1: maximum(_, 1)
compute_λ(ω, ψ, Ω) = minimum(nonzero(((Ω) .^ 3) ./ (2 .* ψ)))

# NOTE: function not used
nonzero(v::Vector{<:Real}) = v[findall(v .!= 0.0)]

function discount(
    Ω::AbstractVector{T}, ψ::AbstractVector{T}, σ::T, τ::AbstractFloat
) where {T<:Real}
    Ω0 = zeros(length(Ω))
    Ωstar = optimize(Ω0, ψ, σ)
    Ωprime = projectsimplex(τ * Ωstar + (1 - τ) * Ω, σ)
    return Ωprime
end
