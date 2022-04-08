@testset "gascost.jl" begin
    # Estimate profit sans gas
    gas = 0.0
    allocs = Dict("0x001" => 1.0, "0x010" => 2.0)
    fake_repository = Repository(
        [Indexer("1x001", 10.0, 0.0, [Allocation("0x001", 2.0), Allocation("0x010", 8.0)])],
        [Subgraph("0x001", 6.0), Subgraph("0x010", 4.0)],
    )
    profit = estimated_profit(fake_repository, allocs, gas)
    @test profit == 2.8

    # Estimate profit with gas
    gas = 1.0
    profit = estimated_profit(fake_repository, allocs, gas)
    @test profit ≈ (-1.8)

    network = Network("1", 30.0, 1.00001, 100, 10.0)
    alloc_list = [Allocation(id, amount) for (id, amount) in allocs]

    # Scale for indexing rewards
    indexing_reward = indexer_subgraph_rewards(fake_repository, network, allocs, 14)
    @test indexing_reward ≈ [0.0845903277130141, 0.03383613108520564]
end
