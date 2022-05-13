@testset "service" begin
    include("../src/exceptions.jl")
    include("../src/domain.jl")
    include("../src/service.jl")

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

    @testset "signals" begin
        repo = Repository(
            [
                Indexer("0x00", 10.0, [Allocation("Qmaaa", 10.0, 0)]),
                Indexer("0x01", 20.0, [Allocation("Qmaaa", 10.0, 0)]),
            ],
            [SubgraphDeployment("1x00", "Qmaaa", 10.0)],
        )

        # Should get the signal of the one defined subgraph
        @test signals(repo) == [10.0]
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
end
