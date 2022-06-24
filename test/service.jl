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
end
