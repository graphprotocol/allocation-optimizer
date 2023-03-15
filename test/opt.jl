# Copyright 2022-, The Graph Foundation
# SPDX-License-Identifier: MIT

@testset "opt" begin
    @testset "optimizeanalytic" begin
        Ω = [1.0, 1.0]
        ψ = [10.0, 10.0]
        σ = 5.0
        @test isapprox(AllocationOpt.optimizeanalytic(Ω, ψ, σ), [2.5, 2.5]; atol=0.1)

        Ω = [1.0, 1.0]
        ψ = [0.0, 10.0]
        σ = 5.0
        @test isapprox(AllocationOpt.optimizeanalytic(Ω, ψ, σ), [0.0, 5.0]; atol=0.1)

        Ω = [1.0, 10000.0]
        ψ = [10.0, 10.0]
        σ = 5.0
        @test isapprox(AllocationOpt.optimizeanalytic(Ω, ψ, σ), [5.0, 0.0]; atol=0.1)
    end

    @testset "lipschitzconstant" begin
        ψ = [0.0, 1.0]
        Ω = [1.0, 1.0]
        @test AllocationOpt.lipschitzconstant(ψ, Ω) == 2.0

        ψ = [0.0, 0.0]
        Ω = [1.0, 1.0]
        @test AllocationOpt.lipschitzconstant(ψ, Ω) == 0.0
    end

    @testset "nonzero" begin
        v = [1.0, 1.0]
        @test AllocationOpt.nonzero(v) == [1.0, 1.0]

        v = [1.0, 0.0]
        @test AllocationOpt.nonzero(v) == [1.0]
    end

    @testset "optimizek" begin
        xopt = [2.5, 2.5]
        Ω = [1.0, 1.0]
        ψ = [10.0, 10.0]
        σ = 5.0
        k = 1
        Φ = 1.0
        Ψ = 20.0
        @test AllocationOpt.optimizek(xopt, Ω, ψ, σ, k, Φ, Ψ) == [5.0, 0.0]

        xopt = [2.5, 2.5]
        Ω = [1.0, 1.0]
        ψ = [10.0, 10.0]
        σ = 5.0
        k = 2
        Φ = 1.0
        Ψ = 20.0
        @test AllocationOpt.optimizek(xopt, Ω, ψ, σ, k, Φ, Ψ) == [2.5, 2.5]
    end

    @testset "optimize" begin
        Ω = [1.0, 1.0]
        ψ = [10.0, 10.0]
        σ = 5.0
        K = 2
        Φ = 1.0
        Ψ = 20.0
        g = 0.01
        xs, nonzeros, profits = AllocationOpt.optimize(Ω, ψ, σ, K, Φ, Ψ, g)
        @test xs == [[5.0 2.5]; [0.0 2.5]]
        @test nonzeros == [1, 2]
        @test isapprox(profits, [[0.41 0.35]; [0.0 0.35]]; atol=0.1)
    end
end
