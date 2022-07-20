@testset "service" begin
    @testset "detach_indexer" begin
        repo = Repository(
            [
                Indexer("0x00", 10.0, [Allocation("Qmaaa", 10.0, 0)]),
                Indexer("0x01", 20.0, [Allocation("Qmaaa", 10.0, 0)]),
            ],
            [SubgraphDeployment("1x00", "Qmaaa", 10.0)],
        )

        # Should detach the specified indexer
        id = "0x00"
        indexer, frepo = detach_indexer(repo, id)
        @test frepo.indexers[1].id == "0x01"
        @test length(frepo.indexers) == 1
        @test indexer.id == "0x00"

        # Should throw an exception when `id` not in repo
        id = "0x10"
        @test_throws UnknownIndexerError detach_indexer(repo, id)
    end

    @testset "signal" begin
        subgraphs = [SubgraphDeployment("1x00", "Qmaaa", 10.0)]

        # Should get the signal of the one defined subgraph
        @test signal.(subgraphs) == [10.0]
    end

    @testset "ipfshash" begin
        subgraphs = [SubgraphDeployment("1x00", "Qmaaa", 10.0)]

        # Should get the ipfshash of the one defined subgraph
        @test ipfshash.(subgraphs) == ["Qmaaa"]
    end

    @testset "allocation" begin
        indexers = [
            Indexer("0x00", 10.0, [Allocation("Qmaaa", 10.0, 0)]),
            Indexer("0x01", 20.0, [Allocation("Qmaaa", 20.0, 0)]),
        ]

        # Should get the allocations of indexers
        @test allocation.(indexers) ==
            [[Allocation("Qmaaa", 10.0, 0)], [Allocation("Qmaaa", 20.0, 0)]]
    end

    @testset "allocated_stake" begin
        allocs = [Allocation("Qmaaa", 10.0, 0), Allocation("Qmaaa", 20.0, 0)]

        # Should get the allocations of indexers
        @test allocated_stake.(allocs) == [10.0, 20.0]
    end

    @testset "stakes" begin
        repo = Repository(
            [
                Indexer(
                    "0x00",
                    10.0,
                    [Allocation("Qmaaa", 10.0, 0), Allocation("Qmbbb", 10.0, 0)],
                ),
                Indexer("0x01", 20.0, [Allocation("Qmaaa", 10.0, 0)]),
            ],
            [SubgraphDeployment("1x00", "Qmaaa", 10.0)],
        )
        # Should get the sum of stake of the one defined subgraph
        @test stakes(repo) == [20.0]

        repo = Repository(
            [
                Indexer("0x00", 10.0, [Allocation("Qmaaa", 10.0, 0)]),
                Indexer("0x01", 20.0, [Allocation("Qmccc", 8.0, 0)]),
            ],
            [
                SubgraphDeployment("1x00", "Qmaaa", 10.0),
                SubgraphDeployment("1x01", "Qmbbb", 5.0),
                SubgraphDeployment("1x01", "Qmccc", 5.0),
            ],
        )

        # Should get proper sum of stake according to the subgraph ids
        @test stakes(repo) == [10.0, 0.0, 8.0]
    end

    @testset "optimize" begin
        repo = Repository(
            [
                Indexer(
                    "0x01", 10.0, [Allocation("Qmaaa", 2.0, 0), Allocation("Qmbbb", 8.0, 0)]
                ),
            ],
            [
                SubgraphDeployment("1x00", "Qmaaa", 10.0),
                SubgraphDeployment("1x01", "Qmbbb", 5.0),
            ],
        )
        indexer = Indexer("0x00", 5.0, Allocation[])
        Ω = stakes(repo)
        ψ = signal.(repo.subgraphs)
        σ = stake(indexer)
        ω = optimize(Ω, ψ, σ)
        @test isapprox(ω, [4.2, 0.8], atol=0.1)
    end

    @testset "projectsimplex" begin
        # Shouldn't project since already on simplex
        x = [5, 2, 8]
        z = 15
        @test projectsimplex(x, z) == x

        # Should set negative value to zero and scale others up
        # to be on simplex
        x = [-5, 2, 8]
        z = 15
        w = projectsimplex(x, z)
        @test sum(w) == z
        @test all(w .≥ 0)
        @test w[1] < w[2] < w[3]

        # Should scale values down to be on simplex
        x = [20, 2, 8]
        z = 15
        w = projectsimplex(x, z)
        @test sum(w) == z
        @test all(w .≥ 0)
        @test w[2] < w[3] < w[1]
    end

    @testset "projectrange" begin
        low = -1
        high = 1
        # Shouldn't project since already within range
        x = [-0.5, 0.2, 0.8]
        @test_skip projectrange.(low, high, x) == x

        # Should set out of range to within
        x = [-5, -0.2, 8]
        w = projectrange.(low, high, x)
        @test_skip maximum(w) == high
        @test_skip minimum(w) == low
        @test_skip w[2] == x[2]
        @test_skip w[1] == low
        @test_skip w[3] == high

        # Should be within the range whatever it is
        x = rand(Int, 10)
        w = projectrange.(low, high, x)
        @test_skip maximum(w) <= high
        @test_skip minimum(w) >= low
    end

    @testset "shrink" begin
        # No need to shrink
        z = [-5, 0, 2, 8]
        α = 0
        y = shrink.(z, α)
        @test_skip y == z

        # Shrink from positives and negatives
        z = [-5, 0, 8]
        α = 1
        y = shrink.(z, α)
        @test_skip y == [-4, 0, 7]

        # Shrink and zeros
        z = [-5, 1, 3, 8]
        α = 3
        y = shrink.(z, α)
        @test_skip y == [-2, 0, 0, 5]
    end

    @testset "∇f" begin
        # ω is 0
        ψ = Float64[5, 2, 8]
        Ω = Float64[2, 1, 1]
        ω = Float64[0, 0, 0]
        df = ∇f.(ω, ψ, Ω)
        @test df ≈ [-2.5, -2, -8]
    end

    @testset "compute_λ" begin
        ψ = [5, 2, 1, 1, 10, 4]
        Ω = [2, 5, 1, 0, 0.1, 5]
        ω = [0, 0, 0, 0, 0, 0]
        λ = compute_λ(ω, ψ, Ω)
        @test_skip isapprox(λ, 5e-5, atol=0.00001)
    end

    @testset "nonzero" begin
        # no zero
        ψ = Float64[5, 2, 1, 1, 10, 4]
        @test_skip nonzero(ψ) == ψ
        # some zero
        Ω = Float64[2, 5, 1, 0, 0.1, 5]
        @test_skip nonzero(Ω) == [2, 5, 1, 0.1, 5]
        # all zero
        ω = Float64[0, 0, 0, 0, 0, 0]
        @test_skip isempty(nonzero(ω))
    end

    @testset "discount" begin
        # τ = 1.0
        Ω = Float64[2, 5, 3]
        ψ = Float64[7, 2, 1]
        σ = 10.0
        τ = 1.0
        Ωnew = discount(Ω, ψ, σ, τ)
        Ω0 = ones(length(Ω))
        @test Ωnew == optimize(Ω0, ψ, σ)

        # τ = 0.0
        τ = 0.0
        Ωnew = discount(Ω, ψ, σ, τ)
        @test Ωnew == Ω

        # τ = 0.2, result should still sum to σ because of simplex projection
        τ = 0.2
        Ωnew = discount(Ω, ψ, σ, τ)
        @test sum(Ωnew) == σ
    end

    @testset "gssp" begin
        # Shouldn't project since already on simplex
        x = [5, 2, 8, 0, 1]
        k = 3
        σ = 15
        @test gssp(x, k, σ) == [5, 2, 8, 0, 0]

        # Should set negative value to zero and scale others up
        # to be on simplex
        x = [-5, 2, 8, -10, -8]
        k = 3
        σ = 15
        @test gssp(x, k, σ) == [0, 4.5, 10.5, 0, 0]

        # Should scale values down to be on simplex
        x = [20, 2, 8, 1, 7]
        k = 3
        σ = 15
        w = gssp(x, k, σ)
        @test sum(w) ≈ σ
        @test all(w .≥ 0)
        @test w[1] > w[3] > w[5]
    end

    @testset "pgd_step" begin
        # ω is 0
        ψ = Float64[5, 2, 8]
        Ω = Float64[2, 1, 1]
        ω = Float64[0, 0, 0]
        k = 2
        σ = 15
        η = 1
        ω₁ = pgd_step(ω, ψ, Ω, k, σ, η)
        @test ω₁ ≈ [4.75, 0.0, 10.25]

        # η is 0
        ψ = Float64[5, 2, 8]
        Ω = Float64[2, 1, 1]
        ω = Float64[0, 0, 0]
        k = 2
        σ = 15
        η = 0
        ω₁ = pgd_step(ω, ψ, Ω, k, σ, η)
        @test ω₁ ≈ [7.5, 7.5, 0.0]
    end

    @testset "pgd" begin
        ψ = Float64[5, 2, 8]
        Ω = Float64[2, 1, 1]
        ω = Float64[0, 0, 0]
        k = 1
        σ = 15
        η = 0.5
        ω₁ = pgd(ω, ψ, Ω, k, σ, η)
        @test ω₁ == [0.0, 0.0, 15.0]
    end
end
