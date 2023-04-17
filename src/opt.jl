# Copyright 2022-, The Graph Foundation
# SPDX-License-Identifier: MIT

"""
    AnalyticOpt{T<:Real,V<:AbstractArray{T},A<:AbstractArray{T},S<:AbstractVector{<:Hook}} <: OptAlgorithm

Optimise the indexing reward analytically.

# Fields
- `x::V` is the current best guess for the solution. Typically zeros.
- `Ω::V` is the allocation vector of other indexers.
- `ψ::A` is the signal vector.
- `σ::T` is the stake.
- `hooks::S` are the hooks

# Example
```julia
julia> using AllocationOpt
julia> using SemioticOpt
julia> x = zeros(2)
julia> Ω = [1.0, 1.0]
julia> ψ = [10.0, 10.0]
julia> σ = 5.0
julia> alg = AllocationOpt.AnalyticOpt(;
           x=x, Ω=Ω, ψ=ψ, σ=σ, hooks=[StopWhen((a; kws...) -> kws[:i] > 1)]
       )
julia> f = x -> x  # This doesn't matter. `f` isn't used by the algorithm.
julia> alg = minimize!(f, alg)
julia> SemioticOpt.x(alg)
2-element Vector{Float64}:
 2.5
 2.5
```
"""
Base.@kwdef struct AnalyticOpt{
    T<:Real,V<:AbstractVector{T},A<:AbstractArray{T},S<:AbstractVector{<:Hook}
} <: SemioticOpt.OptAlgorithm
    x::V
    Ω::V
    ψ::A
    σ::T
    hooks::S
end

"""
    x(a::AnalyticOpt)

Return the current best guess for the solution.
"""
SemioticOpt.x(a::AnalyticOpt) = a.x
"""
    x!(a::AnalyticOpt, v)

In-place setting of `a.x` to `v`

See [`SemioticOpt.x`](@ref).
"""
function SemioticOpt.x!(a::AnalyticOpt, v)
    a.x .= v
    return a
end
SemioticOpt.hooks(a::AnalyticOpt) = a.hooks

"""
    iteration(f::Function, a::AnalyticOpt)

Perform the analytic optimisation.
"""
function SemioticOpt.iteration(f::Function, a::AnalyticOpt)
    ixs = f(SemioticOpt.x(a))
    Ω = a.Ω[ixs]
    ψ = a.ψ[ixs]
    σ = a.σ
    v = dual(Ω, ψ, σ)
    x = primal(Ω, ψ, v)
    y = σsimplex(x, σ)
    return y
end

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
    f(::Any) = 1:length(ψ)
    alg = AllocationOpt.AnalyticOpt(;
        x=zero(ψ), Ω=Ω, ψ=ψ, σ=σ, hooks=[StopWhen((a; kws...) -> kws[:i] > 1)]
    )
    minimize!(f, alg)
    y = SemioticOpt.x(alg)
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
    optimize(Ω, ψ, σ, K, Φ, Ψ, g, config::AbstractDict)

Find the optimal solution vector given allocations of other indexers `Ω`, signals
`ψ`, available stake `σ`, new tokens issued `Φ`, total signal `Ψ`, and gas in grt `g`.


Dispatches to [`optimize`](@ref) with the `opt_mode` key.

If `opt_mode` is `fast`, then run projected gradient descent with GSSP and Halpern.
If `opt_mode` is `optimal`, then run Pairwise Greedy Optimisation.

```julia
julia> using AllocationOpt
julia> config = Dict("opt_mode" => "fast")
julia> Ω = [1.0, 1.0]
julia> ψ = [10.0, 10.0]
julia> σ = 5.0
julia> K = 2
julia> Φ = 1.0
julia> Ψ = 20.0
julia> g = 0.01
julia> xs, nonzeros, profits = AllocationOpt.optimize(Ω, ψ, σ, K, Φ, Ψ, g, config)
([5.0 2.5; 0.0 2.5], Int32[1, 2], [0.4066666666666667 0.34714285714285714; 0.0 0.34714285714285714])
```
"""
function optimize(Ω, ψ, σ, K, Φ, Ψ, g, config::AbstractDict)
    return optimize(Val(Symbol(config["opt_mode"])), Ω, ψ, σ, K, Φ, Ψ, g)
end

"""
    optimize(::Val{:fast}, Ω, ψ, σ, K, Φ, Ψ, g)

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
julia> xs, nonzeros, profits = AllocationOpt.optimize(Val(:fast), Ω, ψ, σ, K, Φ, Ψ, g)
([5.0 2.5; 0.0 2.5], Int32[1, 2], [0.4066666666666667 0.34714285714285714; 0.0 0.34714285714285714])
```
"""
function optimize(::Val{:fast}, Ω, ψ, σ, K, Φ, Ψ, g)
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
    optimize(::Val{:optimal}, Ω, ψ, σ, K, Φ, Ψ, g)

Find the optimal solution vector given allocations of other indexers `Ω`, signals
`ψ`, available stake `σ`, new tokens issued `Φ`, total signal `Ψ`, and gas in grt `g`.

# Example
```julia
julia> using AllocationOpt
julia> Ω = [1.0, 1.0]
julia> ψ = [10.0, 10.0]
julia> σ = 5.0
julia> K = 2
julia> Φ = 1.0
julia> Ψ = 20.0
julia> g = 0.01
julia> xs, nonzeros, profits = AllocationOpt.optimize(
           Val(:optimal), Ω, ψ, σ, K, Φ, Ψ, g
       )
([2.5; 2.5;;], Int32[2], [0.34714285714285714; 0.34714285714285714;;])
```
"""
function optimize(::Val{:optimal}, Ω, ψ, σ, K, Φ, Ψ, g)
    # Helper function to compute profit
    obj = x -> profit.(indexingreward.(x, Ω, ψ, Φ, Ψ), g) |> sum

    # Preallocate solution vectors for in-place operations
    _x = zeros(length(ψ), 1)
    profits = Matrix{Float64}(undef, length(ψ), 1)
    nonzeros = Vector{Int32}(undef, 1)

    f(x, ixs) = ixs

    # Set up optimizer
    function makeanalytic(x)
        return AllocationOpt.AnalyticOpt(;
            x=x, Ω=Ω, ψ=ψ, σ=σ, hooks=[StopWhen((a; kws...) -> kws[:i] > 1)]
        )
    end
    alg = PairwiseGreedyOpt(;
        kmax=K,
        x=zeros(length(ψ)),
        xinit=zeros(length(ψ)),
        f=f,
        a=makeanalytic,
        hooks=[
            StopWhen((a; kws...) -> kws[:f](kws[:z]) ≤ kws[:f](SemioticOpt.x(a)))
            StopWhen(
                (a; kws...) -> length(kws[:z]) == length(SemioticOpt.nonzeroixs(kws[:z]))
            )
        ],
    )
    sol = minimize!(obj, alg)

    _x[:, 1] .= SemioticOpt.x(sol)
    nonzeros[1] = _x[:, 1] |> nonzero |> length
    profits[:, 1] .= profit.(indexingreward.(_x[:, 1], Ω, ψ, Φ, Ψ), g)

    return _x, nonzeros, profits
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
