@testset "optimize.jl" begin

    struct FakeAllocation
        id::String
        amount::Float64
    end
    struct FakeIndexer
        id::String
        stake::Float64
        allocation::NTuple{2, FakeAllocation}
    end
    struct FakeSubgraph
        id::String
        signal::Float64
    end
    struct FakeRepository
        indexers::NTuple{2, FakeIndexer}
        subgraphs::NTuple{2, FakeSubgraph}
    end

    fake_repository = FakeRepository(
        (
            FakeIndexer("0x000", 5.0, (FakeAllocation("0x010", 2.5), FakeAllocation("0x011", 2.5))),
            FakeIndexer("0x001", 10.0, (FakeAllocation("0x010", 2.0), FakeAllocation("0x011", 8.0)))
        ),
        (FakeSubgraph("0x010", 10.0), FakeSubgraph("0x011", 5.0))
    )
    @test_throws ArgumentError optimize("0x000", fake_repository, ("0x010",), ("0x010",))

    allocations = optimize(optimize_id="0x000", repository=fake_repository, blacklist=nothing, whitelist=nothing)
    @test allocations["0x010"] ≈ 4.2
    @test allocations["0x011"] ≈ 0.8

    # allocations = optimize(optimize_id="0x000", repository=fake_repository, blacklist=("0x010",), whitelist=nothing)
    # @test allocations["0x010"] ≈ 0.0
    # @test allocations["0x011"] ≈ 5.0

    # allocations = optimize(optimize_id="0x000", repository=fake_repository, blacklist=nothing, whitelist=("0x010",))
    # @test allocations["0x010"] ≈ 5.0
    # @test allocations["0x011"] ≈ 0.0

    # fake_repository = FakeRepository(
    #     (
    #         FakeIndexer("0x000", 2.0, (FakeAllocation("0x010", 2.0), FakeAllocation("0x011", 0.0))),
    #         FakeIndexer("0x001", 10.0, (FakeAllocation("0x010", 10.0), FakeAllocation("0x011", 4.0)))
    #     ),
    #     (FakeSubgraph("0x010", 1.0), FakeSubgraph("0x011", 5.0))
    # )
    # allocations = optimize(optimize_id="0x000", repository=fake_repository, blacklist=nothing, whitelist=nothing)
    # @test allocations["0x010"] ≈ 0.0
    # @test allocations["0x011"] ≈ 2.0
    @test true
end
