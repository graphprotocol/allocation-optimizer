@testset "data.jl" begin
    fake_repository = Repository(
        [
            Indexer(
                "0x000",
                5.0,
                0.0,
                [Allocation("0x010", 2.5, 14), Allocation("0x011", 2.5, 14)],
            ),
            Indexer(
                "0x001",
                10.0,
                0.0,
                [Allocation("0x010", 2.0, 14), Allocation("0x011", 8.0, 14)],
            ),
        ],
        [Subgraph("0x011", 10.0), Subgraph("0x010", 5.0)],
    )
    alloc_vec = allocation_amounts("0x001", fake_repository)
    @test [8.0, 2.0] == alloc_vec

    # Indexer has no allocations
    fake_repository = Repository(
        [
            Indexer("0x000", 5.0, 0.0, []),
            Indexer(
                "0x001",
                10.0,
                0.0,
                [Allocation("0x010", 2.0, 14), Allocation("0x011", 8.0, 14)],
            ),
        ],
        [Subgraph("0x011", 10.0), Subgraph("0x010", 5.0)],
    )
    alloc_vec = allocation_amounts("0x000", fake_repository)
    @test [0.0, 0.0] == alloc_vec

    # Indexer has allocation that doesn't correspond to a valid subgraph
    fake_repository = Repository(
        [
            Indexer(
                "0x000",
                5.0,
                0.0,
                [Allocation("0x110", 2.5, 14), Allocation("0x011", 2.5, 14)],
            ),
            Indexer(
                "0x001",
                10.0,
                0.0,
                [Allocation("0x010", 2.0, 14), Allocation("0x011", 8.0, 14)],
            ),
        ],
        [Subgraph("0x011", 10.0), Subgraph("0x010", 5.0)],
    )
    @test_throws UnknownSubgraphError allocation_amounts("0x000", fake_repository)

    # Try to get allocation of indexer that doesn't exist
    fake_repository = Repository(
        [
            Indexer(
                "0x000",
                5.0,
                0.0,
                [Allocation("0x010", 2.5, 14), Allocation("0x011", 2.5, 14)],
            ),
            Indexer(
                "0x001",
                10.0,
                0.0,
                [Allocation("0x010", 2.0, 14), Allocation("0x011", 8.0, 14)],
            ),
        ],
        [Subgraph("0x011", 10.0), Subgraph("0x010", 5.0)],
    )
    @test_throws UnknownIndexerError allocation_amounts("0x100", fake_repository)

    # Allocation matrix for full repo
    fake_repository = Repository(
        [
            Indexer(
                "0x000",
                5.0,
                0.0,
                [Allocation("0x010", 2.5, 14), Allocation("0x011", 2.5, 14)],
            ),
            Indexer(
                "0x001",
                10.0,
                0.0,
                [Allocation("0x010", 2.0, 14), Allocation("0x011", 8.0, 14)],
            ),
        ],
        [Subgraph("0x011", 10.0), Subgraph("0x010", 5.0)],
    )
    alloc_vec = allocation_amounts(fake_repository)
    @test [2.5 2.5; 8.0 2.0] == alloc_vec

    # Signals for subgraphs
    ψ = signals(fake_repository)
    @test [10.0, 5.0] == ψ

    # Stakes without delegation for indexers
    σ = stakes(fake_repository)
    @test [5.0, 10.0] == σ

    # Stakes without delegation for indexers
    fake_repository = Repository(
        [
            Indexer(
                "0x000",
                5.0,
                7.0,
                [Allocation("0x010", 2.5, 14), Allocation("0x011", 2.5, 14)],
            ),
            Indexer(
                "0x001",
                10.0,
                2.0,
                [Allocation("0x010", 2.0, 14), Allocation("0x011", 8.0, 14)],
            ),
        ],
        [Subgraph("0x011", 10.0), Subgraph("0x010", 5.0)],
    )
    σ = stakes(fake_repository)
    @test [12.0, 12.0] == σ
end
