using AllocationOpt
using Test
using GraphQLClient

@testset "AllocationOpt.jl" begin
    include("../src/exceptions.jl")
    include("../src/domainmodel.jl")
    include("../src/query.jl")
    include("../src/service.jl")
    include("../src/ActionQueue.jl")

    gateway_url = "https://api.thegraph.com/subgraphs/name/graphprotocol/graph-network-mainnet"

    # Tests
    # include("domainmodel.jl")
    # include("query.jl")
    # include("service.jl")
    # include("actionqueue.jl")

    # @testset "network_state" begin
    #     client = Client(gateway_url)
    #     id = query(client, "indexers"; query_args=Dict("where" => Dict("stakedTokens_gte" => "100000000000000000000000")), output_fields="id").data["indexers"][1]["id"]

    #     @test_throws AllocationOpt.UnknownIndexerError network_state(
    #         "0x6ac85b9d834b51b14a7b0ed849bb5199e",
    #         1,
    #         String[],
    #         String[],
    #         String[],
    #         String[],
    #         gateway_url,
    #     )
    #     @test_throws AllocationOpt.BadSubgraphIpfsHashError network_state(
    #         id, 1, String[""], String[], String[], String[], gateway_url
    #     )
    # end

    # @testset "optimize_indexer" begin
    #     filter_fn = (a, b, c) -> a[:, end]
    #     τ = 0.0
    #     network_id = 1
    #     client = Client(gateway_url)
    #     id = query(client, "indexers"; query_args=Dict("where" => Dict("stakedTokens_gte" => "100000000000000000000000")), output_fields="id").data["indexers"][1]["id"]
    #     all_hashes = [
    #         deployment["ipfsHash"] for deployment in
    #         query(client, "subgraphDeployments"; query_args=Dict("first" => 1000, "where" => Dict("signalledTokens_gte" => "100000000000000000000000")), output_fields="ipfsHash").data["subgraphDeployments"]
    #     ]
    #     ipfshash = all_hashes[1]
    #     another_ipfshash = all_hashes[2]

    #     # Indexer stake should be equal to the sum of allocations
    #     # query indexer's stake
    #     indexer = query(client, "indexers"; query_args=Dict("where" => Dict("id" => id)), output_fields=["delegatedTokens", "stakedTokens", "lockedTokens"]).data["indexers"][1]
    #     stake =
    #         togrt(indexer["delegatedTokens"]) + togrt(indexer["stakedTokens"]) -
    #         togrt(indexer["lockedTokens"])

    #     # run optimize_indexer
    #     repo, optindexer, network = network_state(
    #         id, network_id, String[ipfshash], String[], String[], String[], gateway_url
    #     )
    #     # Check stake
    #     @test isapprox(stake, optindexer.stake; atol=1e-6)
    #     allocs = optimize_indexer(optindexer, repo, repo, 2, τ, filter_fn, String[])
    #     # Sum allocation amounts
    #     ω = sum(values(allocs))
    #     @test isapprox(ω, stake; atol=1e-6)
    #     # Length of allocations is 1
    #     @test length(allocs) == 1
    #     # run optimize_indexer
    #     repo, optindexer, network = network_state(
    #         id,
    #         network_id,
    #         String[ipfshash, another_ipfshash],
    #         String[],
    #         String[],
    #         String[],
    #         gateway_url,
    #     )
    #     allocs = optimize_indexer(optindexer, repo, repo, 2, τ, filter_fn, String[])
    #     # Sum allocation amounts
    #     ω = sum(values(allocs))
    #     @test isapprox(ω, stake; atol=1e-6)
    #     # Length of allocations ≤ length of whitelist
    #     @test length(allocs) ≤ 2

    #     # run optimize_indexer with pinnedlist
    #     pinnedlist = String[another_ipfshash]
    #     repo, optindexer, network = network_state(
    #         id, network_id, String[ipfshash], String[], pinnedlist, String[], gateway_url
    #     )
    #     pinned_allocs = optimize_indexer(
    #         optindexer, repo, repo, 2, τ, filter_fn, pinnedlist
    #     )
    #     # Allocations includes pinnedlist allocatins
    #     @test pinned_allocs[another_ipfshash] == 0.1
    #     # Sum allocation amounts still satisfy stake constraint
    #     ω = sum(values(pinned_allocs))
    #     @test isapprox(ω, stake; atol=1e-6)

    #     # run optimize_indexer with pinnedlist when pinned subgraph is optimal
    #     pinnedlist = String[ipfshash]
    #     repo, optindexer, network = network_state(
    #         id,
    #         network_id,
    #         String[ipfshash, another_ipfshash],
    #         String[],
    #         pinnedlist,
    #         String[],
    #         gateway_url,
    #     )
    #     pinned_allocs = optimize_indexer(
    #         optindexer, repo, repo, 2, τ, filter_fn, pinnedlist
    #     )
    #     # Allocations includes pinnedlist allocatins
    #     @test isapprox(pinned_allocs[ipfshash], allocs[ipfshash]; atol=1e-9)
    #     # Sum allocation amounts still satisfy stake constraint
    #     ω = sum(values(pinned_allocs))
    #     @test isapprox(ω, stake; atol=1e-6)
    # end

    # @testset "read_filterlists" begin
    #     # Should handle CSV input
    #     cols = read_filterlists("example.csv")
    #     @test length(cols[1]) == 2
    # end

    @testset "apply_preferences" begin
        network = AllocationOpt.GraphNetworkParameters("1", 100.0, 1.000003, 30, 15.0, 0)
        gas = 0.0005
        allocation_lifetime = 1
        ω = Float64[0 3; 6 3]
        ψ = Float64[5, 5]
        Ω = Float64[1, 1]
        ωopt = apply_preferences(network, gas, allocation_lifetime, ω, ψ, Ω)
        @test ωopt == Float64[3, 3]
        gas = 1000.0
        @test_throws ArgumentError apply_preferences(
            network, gas, allocation_lifetime, ω, ψ, Ω
        )

        # verbose output
        id = String["Qmaaa", "Qmbbb"]
        gas = 0.0005
        ωopt = apply_preferences(network, gas, allocation_lifetime, ω, ψ, Ω, id)
        @test ωopt == Float64[3, 3]

        gas = 0.001
        ωopt = apply_preferences(network, gas, allocation_lifetime, ω, ψ, Ω, id)
        @test ωopt == Float64[0, 6]

        gas = 0.0005
        allocation_lifetime = 15
        ωopt = apply_preferences(network, gas, allocation_lifetime, ω, ψ, Ω, id)
        @test ωopt == Float64[3, 3]
    end
end
