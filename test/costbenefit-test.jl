@testset "costbenefit.jl" begin
    # Base case
    # Estimate profit and compare with 0 gas, 1 epoch allocation, no preference to keep old allocations
    gas = 0.0
    alloc_lifetime = 1
    preference = 1.0
    allocs = Dict("0x011" => 2.5, "0x010" => 2.5)
    allocs_list = [Allocation("0x010", 2.5, 3), Allocation("0x011", 2.5, 1)]
    fake_repository = Repository(
        [
            Indexer(
                "1x000",
                5.0,
                0.0,
                [
                    Allocation("0x010", 2.5, alloc_lifetime),
                    Allocation("0x011", 2.5, alloc_lifetime),
                ],
            ),
            Indexer(
                "1x001",
                10.0,
                0.0,
                [
                    Allocation("0x010", 2.0, alloc_lifetime),
                    Allocation("0x011", 8.0, alloc_lifetime),
                ],
            ),
        ],
        [Subgraph("0x010", 10.0), Subgraph("0x011", 5.0)],
    )
    fake_filtered_repository = Repository(
        [
            Indexer(
                "1x000",
                3.0,
                0.0,
                [
                    Allocation("0x010", 2.0, alloc_lifetime),
                    Allocation("0x011", 1.0, alloc_lifetime),
                ],
            ),
            Indexer(
                "1x001",
                6.0,
                0.0,
                [
                    Allocation("0x010", 2.0, alloc_lifetime),
                    Allocation("0x011", 4.0, alloc_lifetime),
                ],
            ),
        ],
        [Subgraph("0x010", 10.0), Subgraph("0x011", 15.0)],
    )
    fake_filtered_repository_without_indexer = Repository(
        [
            Indexer(
                "1x001",
                6.0,
                0.0,
                [
                    Allocation("0x010", 2.0, alloc_lifetime),
                    Allocation("0x011", 4.0, alloc_lifetime),
                ],
            ),
        ],
        [Subgraph("0x010", 10.0), Subgraph("0x011", 15.0)],
    )

    network = GraphNetworkParameters("1", 100.0, 1.0001, 15, 15.0, 3)
    fake_network = GraphNetworkParameters("1", 100.0, 1.0001, 15, 25.0, 0)

    # Issuance rate calculation
    issued = issued_token(network, alloc_lifetime)
    @test isapprox(issued, 0.1501; atol=0.0001)

    # Allocate for multiple epochs with issuance compounding
    alloc_lifetime_2 = 21
    issued_2 = issued_token(network, alloc_lifetime_2)
    @test issued_2 > issued * alloc_lifetime_2
    @test issued_2 ≈ (3.1999750303107533)

    # Subgraph rewards calculation
    sgraph_rewards = subgraph_rewards(fake_repository, network, alloc_lifetime)
    @test sgraph_rewards ≈ [0.10007003034241771, 0.050035015171208855]
    @test signal_shares(fake_filtered_repository, fake_network) == [0.4, 0.6]
    @test isapprox(
        subgraph_rewards(fake_filtered_repository, fake_network, alloc_lifetime),
        [0.06, 0.09];
        atol=0.01,
    )

    # Indexing subgraph rewards calculation
    indexing_reward = indexer_subgraph_rewards(
        fake_repository, network, allocs, alloc_lifetime
    )
    @test indexing_reward ≈ [0.019244236604311096, 0.01786964827543173]
    indexing_reward_2 = indexer_subgraph_rewards(
        fake_filtered_repository_without_indexer,
        fake_network,
        allocations_by_indexer("1x000", fake_filtered_repository),
        alloc_lifetime,
    )
    @test isapprox(indexing_reward_2, [0.03, 0.018]; atol=0.0001)

    # Profit should be equal to indexing rewards since gas == 0
    estimated_prof = estimated_profit(fake_repository, allocs, gas, network, alloc_lifetime)
    @test indexing_reward ≈ estimated_prof

    # After getting optimize to run correctly, check against trivial allocation above and compare_rewards
    optimized_alloc_list, optimized_filterd_repo = optimize(
        "1x001", fake_repository, gas, network, alloc_lifetime, preference, nothing, nothing
    )
    # add one for optimized_alloc_list = Dict("0x011" => 3.7132034355964256, "0x010" => 6.2867965644035735)
    allocs_list = filter(
        a -> a.amount != 0,
        map(
            alloc_id -> Allocation(alloc_id, optimized_alloc_list[alloc_id], 0),
            collect(keys(optimized_alloc_list)),
        ),
    )
    # Whatever the original allocations are, the optimized solution should be at least as much
    indexing_reward_3 = indexer_subgraph_rewards(
        optimized_filterd_repo, network, optimized_alloc_list, alloc_lifetime
    )
    @test indexing_reward <= indexing_reward_3

    fake_filtered_repository = Repository(
        [
            Indexer(
                "1x000",
                3.0,
                0.0,
                [Allocation("0x010", 2.0, 0), Allocation("0x011", 1.0, 0)],
            ),
            Indexer(
                "1x001",
                6.0,
                0.0,
                [Allocation("0x010", 2.0, 0), Allocation("0x011", 4.0, 0)],
            ),
        ],
        [Subgraph("0x010", 10.0), Subgraph("0x011", 15.0)],
    )
    # Compare rewards of current vs the filtered repo + allocation results - gas

    compared = compare_rewards(
        "1x000",
        fake_filtered_repository_without_indexer,
        fake_filtered_repository,
        fake_network,
        allocations_by_indexer("1x000", fake_filtered_repository),
        alloc_lifetime,
        0.0,
        1.0,
    )
    @test compared == [0, 0]
    fake_network_day_2 = GraphNetworkParameters("1", 100.0, 1.0001, 15, 25.0, 1)
    compared_day_2 = compare_rewards(
        "1x000",
        fake_filtered_repository_without_indexer,
        fake_filtered_repository,
        fake_network_day_2,
        allocations_by_indexer("1x000", fake_filtered_repository),
        alloc_lifetime,
        gas,
        1.0,
    )
    @test compared_day_2 == indexing_reward_2

    # test create actions with different time in the network
    actions = create_actions(
        "1x000",
        fake_filtered_repository_without_indexer,
        fake_filtered_repository,
        fake_network,
        allocations_by_indexer("1x000", fake_filtered_repository),
        alloc_lifetime,
        gas,
        1.0,
        nothing,
    )
    @test length(actions[1]) == 2

    actions_2 = create_actions(
        "1x000",
        fake_filtered_repository_without_indexer,
        fake_filtered_repository,
        fake_network_day_2,
        allocations_by_indexer("1x000", fake_filtered_repository),
        alloc_lifetime,
        gas,
        1.0,
        nothing,
    )
    @test length(actions_2[3]) == 2

    # Test for the other player
    optimized_alloc_list_2, optimized_filterd_repo_2 = optimize(
        "1x000", fake_repository, gas, network, alloc_lifetime, preference, nothing, nothing
    )
    alloc_list_2 = map(
        a -> Allocation(a, optimized_alloc_list_2[a], network.current_epoch),
        collect(keys(optimized_alloc_list_2)),
    )
    compared = compare_rewards(
        "1x000",
        optimized_filterd_repo_2,
        fake_repository,
        network,
        alloc_list_2,
        alloc_lifetime,
        gas,
        1.0,
    )
    actions_3 = create_actions(
        "1x000",
        optimized_filterd_repo_2,
        fake_repository,
        network,
        alloc_list_2,
        alloc_lifetime,
        gas,
        1.0,
        nothing,
    )
    @test length(actions_3[1]) == 1

    # Test gas calculations
    gas = 0.1
    tx_size = 2.3
    profit_gas = estimated_profit(fake_repository, allocs, gas, network, alloc_lifetime)
    indexing_reward_gas = indexer_subgraph_rewards(
        fake_repository, network, allocs, alloc_lifetime
    )
    @test sum(estimated_prof - profit_gas) ≈ length(allocs) * gas * tx_size
end
