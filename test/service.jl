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
        ω = optimize(indexer, repo)
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
        @test projectrange.(low, high, x) == x

        # Should set out of range to within
        x = [-5, -0.2, 8]
        w = projectrange.(low, high, x)
        @test maximum(w) == high
        @test minimum(w) == low
        @test w[2] == x[2]
        @test w[1] == low
        @test w[3] == high

        # Should be within the range whatever it is
        x = rand(Int, 10)
        w = projectrange.(low, high, x)
        @test maximum(w) <= high
        @test minimum(w) >= low
    end

    @testset "shrink" begin
        # No need to shrink
        z = [-5, 0, 2, 8]
        α = 0
        y = shrink.(z, α)
        @test y == z

        # Shrink from positives and negatives
        z = [-5, 0, 8]
        α = 1
        y = shrink.(z, α)
        @test y == [-4, 0, 7]

        # Shrink and zeros
        z = [-5, 1, 3, 8]
        α = 3
        y = shrink.(z, α)
        @test y == [-2, 0, 0, 5]
    end

    @testset "∇f" begin
        # ω and p are 0
        ψ = Float64[5, 2, 8]
        Ω = Float64[2, 1, 1]
        ω = Float64[0, 0, 0]
        p = Float64[0, 0, 0]
        μ = 0.1
        df = ∇f.(ω, ψ, Ω, μ, p)
        @test df ≈ [-2.5, -2, -8]

        # ω and p are 1
        ψ = Float64[5, 2, 8]
        Ω = Float64[2, 1, 1]
        ω = Float64[1, 1, 1]
        p = Float64[1, 1, 1]
        μ = 0.1
        df = ∇f.(ω, ψ, Ω, μ, p)
        @test df == [-10 / 9 - 0.1, -0.6, -2.1]

        # various numbers
        ψ = Float64[4, 5, 8]
        Ω = Float64[1, 3, 4]
        ω = Float64[3, 1, 4]
        p = Float64[0.1, 10, 2]
        μ = 0.1
        df = ∇f.(ω, ψ, Ω, μ, p)
        @test df == [-0.26, -1.9375, -0.7]
    end

    @testset "compute_λ" begin
        ψ = [5, 2, 1, 1, 10, 4]
        Ω = [2, 5, 1, 0, 0.1, 5]
        ω = [0, 0, 0, 0, 0, 0]
        λ = compute_λ(ω, ψ, Ω)
        @test isapprox(λ, 5e-5, atol=0.00001)
    end

    @testset "nonzero" begin
        # no zero
        ψ = [5, 2, 1, 1, 10, 4]
        @test nonzero(ψ) == ψ
        # some zero
        Ω = [2, 5, 1, 0, 0.1, 5]
        @test nonzero(Ω) == [2, 5, 1, 0.1, 5]
        # all zero
        ω = [0, 0, 0, 0, 0, 0]
        @test isempty(nonzero(ω))
    end
end
