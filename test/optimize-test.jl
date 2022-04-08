@testset "optimize.jl" begin
    fake_repository = Repository(
        [
            Indexer(
                "0x000", 5.0, 0.0, [Allocation("0x010", 2.5), Allocation("0x011", 2.5)]
            ),
            Indexer(
                "0x001", 10.0, 0.0, [Allocation("0x010", 2.0), Allocation("0x011", 8.0)]
            ),
        ],
        [Subgraph("0x010", 10.0), Subgraph("0x011", 5.0)],
    )
    @test_throws ArgumentError optimize("0x000", fake_repository, ("0x010",), ("0x010",))

    allocations, _ = optimize("0x000", fake_repository, nothing, nothing)
    @test isapprox(allocations["0x010"], 4.2; atol=0.1)
    @test isapprox(allocations["0x011"], 0.8; atol=0.1)

    allocations, _ = optimize("0x000", fake_repository, nothing, ["0x010"])
    @test allocations["0x011"] ≈ 5.0

    allocations, _ = optimize("0x000", fake_repository, ["0x010"], nothing)
    @test allocations["0x010"] ≈ 5.0

    fake_repository = Repository(
        [
            Indexer(
                "0x000", 2.0, 0.0, [Allocation("0x010", 2.0), Allocation("0x011", 0.0)]
            ),
            Indexer(
                "0x001", 10.0, 0.0, [Allocation("0x010", 10.0), Allocation("0x011", 4.0)]
            ),
        ],
        [Subgraph("0x010", 1.0), Subgraph("0x011", 5.0)],
    )
    allocations, _ = optimize("0x000", fake_repository, nothing, nothing)
    @test allocations["0x010"] ≈ 0.0
    @test allocations["0x011"] ≈ 2.0

    # Test incorporating gas fees
    gas = 1.0
    fake_repository = Repository(
        [
            Indexer(
                "0x000", 5.0, 0.0, [Allocation("0x010", 2.5), Allocation("0x011", 2.5)]
            ),
            Indexer(
                "0x001", 10.0, 0.0, [Allocation("0x010", 2.0), Allocation("0x011", 8.0)]
            ),
        ],
        [Subgraph("0x011", 10.0), Subgraph("0x010", 5.0)],
    )
end
