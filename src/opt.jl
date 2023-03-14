# Copyright 2022-, The Graph Foundation
# SPDX-License-Identifier: MIT

"""
    optimizeanalytic(Ω, ψ, σ)

Optimise analytically over existing allocation vector `Ω`, signals `ψ`, and stake `σ`.

```julia
julia> Ω = [1.0, 7.0]
julia> ψ = [10.0, 5.0]
julia> σ = 5.0
julia> AllocationOpt.optimizeanalytic(Ω, ψ, σ)
```
"""
function optimizeanalytic(Ω, ψ, σ)
    v = dual(Ω, ψ, σ)
    x = primal(Ω, ψ, v)
    y = σsimplex(x, σ)
    return y
end

"""
    primal(Ω, ψ, v)

Analytic solution of the primal form of the optimisation problem given signals `ψ`,
allocations `Ω`, and a dual solution vector `v`.

!!! note
    You should probably not use this function directly. Use [`optimizeanalytic`](@ref) instead.

```julia
julia> Ω = [1.0, 7.0]
julia> ψ = [10.0, 5.0]
julia> v = [1.0, 10.0, 2.0]
julia> AllocationOpt.dual(Ω, ψ, v)
```
"""
primal(Ω, ψ, v) = max.(0.0, .√(ψ .* Ω / v) - Ω)

"""
    dual(Ω, ψ, σ)

Analytic solution of the dual form of the optimisation problem given signals `ψ`,
allocation vector `Ω`, and stake `σ`.

!!! note
    You should probably not use this function directly. Use [`optimizeanalytic`](@ref) instead.

```julia
julia> Ω = [1.0, 7.0]
julia> ψ = [10.0, 5.0]
julia> σ = 5.0
julia> AllocationOpt.dual(Ω, ψ, σ)
```
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
