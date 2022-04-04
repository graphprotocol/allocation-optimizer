@testset "AllocationOpt" begin

  gas_fee = 0.3
  repository = Repository(
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

  allocations = allocation_optimization("0x000", repository, gas_fee)

  @test allocations["0x011"] ≈ 5.0
end
