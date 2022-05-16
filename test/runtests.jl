using AllocationOpt
using Test

@testset "AllocationOpt.jl" begin
    include("../src/exceptions.jl")
    include("../src/domainmodel.jl")
    include("../src/query.jl")
    include("../src/service.jl")

    # Tests
    include("domainmodel.jl")
    include("query.jl")
    include("service.jl")

    @testset "optimize_indexer" begin
        client = gql_client()

        id = query(client, "indexers"; query_args=Dict("where" => Dict("stakedTokens_gte" => "100000000000000000000000")), output_fields="id").data["indexers"][1]["id"]

        all_hashes = [
            deployment["ipfsHash"] for deployment in
            query(client, "subgraphDeployments"; query_args=Dict("first" => 1000, "where" => Dict("signalledTokens_gte" => "1000000000000000000000")), output_fields="ipfsHash").data["subgraphDeployments"]
        ]
        ipfshash = all_hashes[1]
        another_ipfshash = all_hashes[2]
        @test_throws AllocationOpt.UnknownIndexerError optimize_indexer(
            "0x6ac85b9d834b51b14a7b0ed849bb5199e", String[], String[], String[], String[]
        )
        @test_throws AllocationOpt.BadSubgraphIpfsHashError optimize_indexer(
            id, String[""], String[ipfshash], String[], String[]
        )

        # Indexer stake should be equal to the sum of allocations
        # query indexer's stake
        indexer = query(client, "indexers"; query_args=Dict("where" => Dict("id" => id)), output_fields=["delegatedTokens", "stakedTokens"]).data["indexers"][1]
        stake = togrt(indexer["delegatedTokens"]) + togrt(indexer["stakedTokens"])
        # run optimize_indexer
        allocs = optimize_indexer(id, String[ipfshash], String[], String[], String[])
        # Sum allocation amounts
        ω = sum(map(x -> x[2], allocs))
        @test isapprox(ω, stake; atol=1e-6)
        # Length of allocations is 1
        @test length(allocs) == 1
        # run optimize_indexer
        allocs = optimize_indexer(
            id, String[ipfshash, another_ipfshash], String[], String[], String[]
        )
        # Sum allocation amounts
        ω = sum(map(x -> x[2], allocs))
        @test isapprox(ω, stake; atol=1e-6)
        # Length of allocations is 2
        @test length(allocs) == 2
    end
end