@testset "costbenefit.jl" begin
    # Estimate profit sans gas
    gas = 0.0
    allocs = Dict("0x001" => 1.0, "0x010" => 2.0)
    fake_repository = Repository(
        [Indexer("1x001", 10.0, 0.0, [Allocation("0x001", 2.0, 4), Allocation("0x010", 8.0, 10)])],
        [Subgraph("0x001", 6.0), Subgraph("0x010", 4.0)],
    )
    network = Network("1", 100.0, 1.001, 10, 10.0, 14) 

    profit = sum(estimated_profit(fake_repository, allocs, gas, network, 4))
    @test profit ≈ (1.1421192174520958)

    # Estimate profit with gas
    gas = 1.0
    profit = sum(estimated_profit(fake_repository, allocs, gas, network, 4))
    @test profit ≈ (-3.4578807825479037)

    # Scale for indexing rewards
    indexing_reward = indexer_subgraph_rewards(fake_repository, network, allocs, 14)
    @test indexing_reward ≈ [3.0038667228971545, 1.201546689158862]

    @test issued_token(network, 4) ≈ (4.078997205186056)

    # estimated_profit = estimated_profit(fake_repository, allocs, 2, )
end
