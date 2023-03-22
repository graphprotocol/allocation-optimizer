# Copyright 2022-, The Graph Foundation
# SPDX-License-Identifier: MIT

"""
    optimizeanalytic(Ω, ψ, σ)

Optimise analytically over existing allocation vector `Ω`, signals `ψ`, and stake `σ`.

```julia
julia> using AllocationOpt
julia> Ω = [1.0, 7.0]
julia> ψ = [10.0, 5.0]
julia> σ = 5.0
julia> AllocationOpt.optimizeanalytic(Ω, ψ, σ)
2-element Vector{Float64}:
 3.5283092056122474
 1.4716907943877526
```
"""
function optimizeanalytic(Ω, ψ, σ)
    v = dual(Ω, ψ, σ)
    x = primal(Ω, ψ, v)
    y = σsimplex(x, σ)
    return y
end

"""
    primal(Ω, ψ, ν)

Analytic solution of the primal form of the optimisation problem given signals `ψ`,
allocations `Ω`, and a dual solution vector `ν`.

!!! note
    You should probably not use this function directly. Use [`optimizeanalytic`](@ref) instead.
"""
primal(Ω, ψ, ν) = max.(0.0, .√(ψ .* Ω / ν) - Ω)

"""
    dual(Ω, ψ, σ)

Analytic solution of the dual form of the optimisation problem given signals `ψ`,
allocation vector `Ω`, and stake `σ`.

!!! note
    You should probably not use this function directly. Use [`optimizeanalytic`](@ref) instead.
"""
function dual(Ω, ψ, σ)
    lower_bound = eps(Float64)
    upper_bound = (sum(.√(ψ .* Ω)))^2 / σ
    sol = find_zero(
        x -> sum(max.(0.0, .√(ψ .* Ω / x) .- Ω)) - σ,
        (lower_bound, upper_bound),
        Roots.Brent(),
    )
    return sol
end

"""
    optimize(Ω, ψ, σ, K, Φ, Ψ, g)

Find the optimal vectors for k ∈ [1,`K`] given allocations of other indexers `Ω`, signals
`ψ`, available stake `σ`, new tokens issued `Φ`, total signal `Ψ`, and gas in grt `g`.

```julia
julia> using AllocationOpt
julia> Ω = [1.0, 1.0]
julia> ψ = [10.0, 10.0]
julia> σ = 5.0
julia> K = 2
julia> Φ = 1.0
julia> Ψ = 20.0
julia> g = 0.01
julia> xs, nonzeros, profits = AllocationOpt.optimize(Ω, ψ, σ, K, Φ, Ψ, g)
([5.0 2.5; 0.0 2.5], Int32[1, 2], [0.4066666666666667 0.34714285714285714; 0.0 0.34714285714285714])
```
"""
function optimize(Ω, ψ, σ, K, Φ, Ψ, g)
    # Helper function to compute profit
    f = x -> profit.(indexingreward.(x, Ω, ψ, Φ, Ψ), g)

    # Get the anchor point for Halpern iteration
    xopt = optimizeanalytic(Ω, ψ, σ)

    # Preallocate solution vectors for in-place operations
    x = repeat(xopt, 1, K)
    profits = Matrix{Float64}(undef, length(xopt), K)
    nonzeros = Vector{Int32}(undef, K)

    # Optimize
    for k in 1:K
        x[:, k] .= AllocationOpt.optimizek(x[:, k], Ω, ψ, σ, k, Φ, Ψ)
        nonzeros[k] = x[:, k] |> nonzero |> length
        profits[:, k] .= f(x[:, k])
    end

    return x, nonzeros, profits
end

"""
    optimizek(Ω, ψ, σ, k, Φ, Ψ)

Find the optimal `k` sparse vector given allocations of other indexers `Ω`, signals
`ψ`, available stake `σ`, new tokens issued `Φ`, and total signal `Ψ`.

```julia
julia> using AllocationOpt
julia> xopt = [2.5, 2.5]
julia> Ω = [1.0, 1.0]
julia> ψ = [10.0, 10.0]
julia> σ = 5.0
julia> k = 1
julia> Φ = 1.0
julia> Ψ = 20.0
julia> AllocationOpt.optimizek(xopt, Ω, ψ, σ, k, Φ, Ψ)
2-element Vector{Float64}:
 5.0
 0.0
```
"""
function optimizek(xopt, Ω, ψ, σ, k, Φ, Ψ)
    projection = x -> gssp(x, k, σ)
    alg = ProjectedGradientDescent(;
        x=xopt,
        η=stepsize(lipschitzconstant(ψ, Ω)),
        hooks=[
            StopWhen((a; kws...) -> norm(x(a) - kws[:z]) < 1e-32),
            HalpernIteration(; x₀=xopt, λ=i -> 1.0 / i),
        ],
        t=projection,
    )
    f = x -> indexingreward(x, ψ, Ω, Φ, Ψ)
    sol = minimize!(f, alg)
    return floor.(SemioticOpt.x(sol); digits=1)
end

"""
    lipschitzconstant(ψ, Ω)

The Lipschitz constant of the indexing reward function given signals `ψ` and
allocations `Ω`.

```julia
julia> using AllocationOpt
julia> ψ = [0.0, 1.0]
julia> Ω = [1.0, 1.0]
julia> AllocationOpt.lipschitzconstant(ψ, Ω)
2.0
```
"""
lipschitzconstant(ψ, Ω) = maximum(2 * ψ ./ Ω .^ 3)

"""
    nonzero(v::AbstractVector)

Get the non-zero elements of vector `v`.

```julia
julia> using AllocationOpt
julia> v = [0.0, 1.0]
julia> AllocationOpt.nonzero(v)
1-element view(::Vector{Float64}, [2]) with eltype Float64:
 1.0
```
"""
nonzero(v::AbstractVector) = SAC.filterview(x -> x != 0, v)
