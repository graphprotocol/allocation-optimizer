# Copyright 2022-, The Graph Foundation
# SPDX-License-Identifier: MIT

@testset "opt" begin
    @testset "SemioticOpt analytic" begin
        x = zeros(2)
        Ω = [1.0, 1.0]
        ψ = [10.0, 10.0]
        σ = 5.0
        f(::Any) = 1:length(ψ)
        alg = AllocationOpt.AnalyticOpt(;
            x=x, Ω=Ω, ψ=ψ, σ=σ, hooks=[StopWhen((a; kws...) -> kws[:i] > 1)]
        )
        alg = minimize!(f, alg)
        @test isapprox(SemioticOpt.x(alg), [2.5, 2.5]; atol=0.1)

        x = zeros(2)
        Ω = [1.0, 1.0]
        ψ = [0.0, 10.0]
        σ = 5.0
        alg = AllocationOpt.AnalyticOpt(;
            x=x, Ω=Ω, ψ=ψ, σ=σ, hooks=[StopWhen((a; kws...) -> kws[:i] > 1)]
        )
        alg = minimize!(f, alg)
        @test isapprox(SemioticOpt.x(alg), [0.0, 5.0]; atol=0.1)

        x = zeros(2)
        Ω = [1.0, 10000.0]
        ψ = [10.0, 10.0]
        σ = 5.0
        alg = AllocationOpt.AnalyticOpt(;
            x=x, Ω=Ω, ψ=ψ, σ=σ, hooks=[StopWhen((a; kws...) -> kws[:i] > 1)]
        )
        alg = minimize!(f, alg)
        @test isapprox(SemioticOpt.x(alg), [5.0, 0.0]; atol=0.1)
    end

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
        @testset "fastgas" begin
            x₀ = [2.5, 2.5]
            Ω = [1.0, 1.0]
            ψ = [10.0, 10.0]
            σ = 5.0
            k = 1
            Φ = 1.0
            Ψ = 20.0
            @test AllocationOpt.optimizek(Val(:fastgas), x₀, Ω, ψ, σ, k, Φ, Ψ) == [5.0, 0.0]

            x₀ = [2.5, 2.5]
            Ω = [1.0, 1.0]
            ψ = [10.0, 10.0]
            σ = 5.0
            k = 2
            Φ = 1.0
            Ψ = 20.0
            @test AllocationOpt.optimizek(Val(:fastgas), x₀, Ω, ψ, σ, k, Φ, Ψ) == [2.5, 2.5]
        end

        @testset "optimal" begin
            Ω = [1.0, 1.0]
            ψ = [10.0, 10.0]
            σ = 5.0
            k = 1
            Φ = 1.0
            Ψ = 20.0
            g = 0.01
            x₀ = zeros(length(Ω))
            x = AllocationOpt.optimizek(Val(:optimal), x₀, Ω, ψ, σ, k, Φ, Ψ, g)
            @test x == [5.0, 0.0]

            Ω = [1.0, 1.0]
            ψ = [10.0, 10.0]
            σ = 5.0
            k = 2
            Φ = 1.0
            Ψ = 20.0
            g = 0.01
            x₀ = zeros(length(Ω))
            x = AllocationOpt.optimizek(Val(:optimal), x₀, Ω, ψ, σ, k, Φ, Ψ, g)
            @test x == [2.5, 2.5]
        end
    end

    @testset "optimize" begin
        @testset "fastnogas" begin
            rixs = [1, 2]
            Ω = [1.0, 1.0]
            ψ = [10.0, 10.0]
            σ = 5.0
            K = 2
            Φ = 1.0
            Ψ = 20.0
            g = 0.0
            xs, nonzeros, profits = AllocationOpt.optimize(
                Val(:fastnogas), Ω, ψ, σ, K, Φ, Ψ, g, rixs
            )
            @test xs == [2.5; 2.5;;]
            @test nonzeros == [2]
            @test isapprox(profits, [0.35; 0.35]; atol=0.1)

            rixs = [2]
            Ω = [1.0, 1.0]
            ψ = [10.0, 10.0]
            σ = 5.0
            K = 1
            Φ = 1.0
            Ψ = 20.0
            g = 0.0
            xs, nonzeros, profits = AllocationOpt.optimize(
                Val(:fastnogas), Ω, ψ, σ, K, Φ, Ψ, g, rixs
            )
            @test xs == [0.0; 5.0;;]
            @test nonzeros == [1]
            @test isapprox(profits, [0.0, 0.41]; atol=0.1)
        end

        @testset "fastgas" begin
            rixs = [1, 2]
            Ω = [1.0, 1.0]
            ψ = [10.0, 10.0]
            σ = 5.0
            K = 2
            Φ = 1.0
            Ψ = 20.0
            g = 0.01
            xs, nonzeros, profits = AllocationOpt.optimize(
                Val(:fastgas), Ω, ψ, σ, K, Φ, Ψ, g, rixs
            )
            @test xs == [[5.0 2.5]; [0.0 2.5]]
            @test nonzeros == [1, 2]
            @test isapprox(profits, [[0.41 0.35]; [0.0 0.35]]; atol=0.1)

            rixs = [2]
            Ω = [1.0, 1.0]
            ψ = [10.0, 10.0]
            σ = 5.0
            K = 1
            Φ = 1.0
            Ψ = 20.0
            g = 0.01
            xs, nonzeros, profits = AllocationOpt.optimize(
                Val(:fastgas), Ω, ψ, σ, K, Φ, Ψ, g, rixs
            )
            @test xs == [0.0; 5.0;;]
            @test nonzeros == [1]
            @test isapprox(profits, [0.0, 0.41]; atol=0.1)
        end

        @testset "optimal" begin
            rixs = [1, 2]
            Ω = [1.0, 1.0]
            ψ = [10.0, 10.0]
            σ = 5.0
            K = 2
            Φ = 1.0
            Ψ = 20.0
            g = 0.01
            xs, nonzeros, profits = AllocationOpt.optimize(
                Val(:optimal), Ω, ψ, σ, K, Φ, Ψ, g, rixs
            )
            @test xs == [[5.0 2.5]; [0.0 2.5]]
            @test nonzeros == [1, 2]
            @test isapprox(profits, [[0.41 0.35]; [0.0 0.35]]; atol=0.1)

            rixs = [2]
            Ω = [1.0, 1.0]
            ψ = [10.0, 10.0]
            σ = 5.0
            K = 1
            Φ = 1.0
            Ψ = 20.0
            g = 0.01
            xs, nonzeros, profits = AllocationOpt.optimize(
                Val(:optimal), Ω, ψ, σ, K, Φ, Ψ, g, rixs
            )
            @test xs == [0.0; 5.0;;]
            @test nonzeros == [1]
            @test isapprox(profits, [0.0, 0.41]; atol=0.1)

            # Test Early stopping
            # Should run the final iteration
            rixs = [1, 2, 3, 4]
            Ω = [1.0, 1.0, 1.0, 1.0]
            ψ = [10.0, 10.0, 0.01, 0.01]
            σ = 5.0
            K = 4
            Φ = 1.0
            Ψ = 20.0
            g = 0.01
            xs, nonzeros, profits = AllocationOpt.optimize(
                Val(:optimal), Ω, ψ, σ, K, Φ, Ψ, g, rixs
            )
            @test xs ≈ [
                [5.0 2.5 2.5 0.0]
                [0.0 2.5 2.5 0.0]
                [0.0 0.0 0.0 0.0]
                [0.0 0.0 0.0 0.0]
            ]
            @test nonzeros == [1, 2, 2, 1]
            @test isapprox(
                profits,
                [
                    [0.406667 0.347143 0.347143 0.0]
                    [0.0 0.347143 0.347143 0.0]
                    [0.0 0.0 0.0 0.0]
                    [0.0 0.0 0.0 0.0]
                ];
                atol=0.1,
            )
        end

        @testset "dispatch" begin
            config = Dict("opt_mode" => "fastnogas")
            rixs = [1, 2]
            Ω = [1.0, 1.0]
            ψ = [10.0, 10.0]
            σ = 5.0
            K = 2
            Φ = 1.0
            Ψ = 20.0
            g = 0.01
            xs, nonzeros, profits = AllocationOpt.optimize(
                Ω, ψ, σ, K, Φ, Ψ, g, rixs, config
            )
            @test xs == [2.5; 2.5;;]
            @test nonzeros == [2]
            @test isapprox(profits, [0.35; 0.35]; atol=0.1)

            config = Dict("opt_mode" => "fastgas")
            rixs = [1, 2]
            Ω = [1.0, 1.0]
            ψ = [10.0, 10.0]
            σ = 5.0
            K = 2
            Φ = 1.0
            Ψ = 20.0
            g = 0.01
            xs, nonzeros, profits = AllocationOpt.optimize(
                Ω, ψ, σ, K, Φ, Ψ, g, rixs, config
            )
            @test xs == [[5.0 2.5]; [0.0 2.5]]
            @test nonzeros == [1, 2]
            @test isapprox(profits, [[0.41 0.35]; [0.0 0.35]]; atol=0.1)

            config = Dict("opt_mode" => "optimal")
            rixs = [1, 2]
            Ω = [1.0, 1.0]
            ψ = [10.0, 10.0]
            σ = 5.0
            K = 2
            Φ = 1.0
            Ψ = 20.0
            g = 0.01
            xs, nonzeros, profits = AllocationOpt.optimize(
                Ω, ψ, σ, K, Φ, Ψ, g, rixs, config
            )
            @test xs == [[5.0 2.5]; [0.0 2.5]]
            @test nonzeros == [1, 2]
            @test isapprox(profits, [[0.41 0.35]; [0.0 0.35]]; atol=0.1)
        end
    end
end
