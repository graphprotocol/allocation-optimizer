@testset "costbenefit.jl" begin
    # Base case
    # Estimate profit and compare with 0 gas, 1 epoch allocation, no preference to keep old allocations
    gas = 0.0
    alloc_lifetime = 1
    preference=1.0
    allocs = Dict("0x011" => 2.5, "0x010" => 2.5)
    fake_repository = Repository(
        [
            Indexer(
                "1x000", 5.0, 0.0, [Allocation("0x010", 2.5, 14), Allocation("0x011", 2.5, alloc_lifetime)]
            ),
            Indexer(
                "1x001", 10.0, 0.0, [Allocation("0x010", 2.0, 14), Allocation("0x011", 8.0, alloc_lifetime)]
            ),
        ],
        [Subgraph("0x010", 10.0), Subgraph("0x011", 5.0)],
    )
    network = Network("1", 100.0, 1.0001, 15, 15.0, 14) 

    # Issuance rate calculation
    issued = issued_token(network, alloc_lifetime)
    @test issued ≈ (0.15010504551362658)

    # Allocate for multiple epochs with issuance compounding
    alloc_lifetime_2 = 21
    issued_2 = issued_token(network, alloc_lifetime_2)
    @test issued_2 > issued * alloc_lifetime_2
    @test issued_2 ≈ (3.1999750303107533)

    # Subgraph rewards calculation
    sgraph_rewards = subgraph_rewards(fake_repository, network, alloc_lifetime)
    @test sgraph_rewards ≈ [0.10007003034241771, 0.050035015171208855]

    # Indexing subgraph rewards calculation
    indexing_reward = indexer_subgraph_rewards(fake_repository, network, allocs, alloc_lifetime)
    @test indexing_reward ≈ [0.019244236604311096, 0.01786964827543173]

    # Profit should be equal to indexing rewards since gas == 0
    estimated_prof = estimated_profit(fake_repository, allocs, gas, network, alloc_lifetime)
    @test indexing_reward ≈ estimated_prof

    # Ater getting optimize to run correctly, check against trivial allocation above and compare_rewards
    optimized_alloc_list, optimized_filterd_repo = optimize("1x001", fake_repository, gas, network, alloc_lifetime, nothing, nothing)
    # add one for optimized_alloc_list = Dict("0x011" => 3.7132034355964256, "0x010" => 6.2867965644035735)

    # Whatever the original allocations are, the optimized solution should be at least as much
    indexing_reward_2 = indexer_subgraph_rewards(optimized_filterd_repo, network, optimized_alloc_list, alloc_lifetime)
    @test indexing_reward <= indexing_reward_2

    # Compare rewards of current vs the filtered repo + allocation results - gas
    compared = compare_rewards("1x001", optimized_filterd_repo, fake_repository, network, allocs, alloc_lifetime, gas, 1.0)
    @test sum(compared) >= 0

    # Test gas calculations
    gas = 0.1
    tx_size = 2.3
    profit_gas = estimated_profit(fake_repository, allocs, gas, network, alloc_lifetime)
    indexing_reward_gas = indexer_subgraph_rewards(fake_repository, network, allocs, alloc_lifetime) 
    @test sum(estimated_prof - profit_gas) ≈ length(allocs) * gas * tx_size
end
