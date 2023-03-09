# Copyright 2022-, The Graph Foundation
# SPDX-License-Identifier: MIT

@testset "data" begin
    @testset "squery" begin
        v, a, f = AllocationOpt.squery()
        @test v == "subgraphDeployments"
        @test f == ["ipfsHash", "signalledTokens"]
        @test a == Dict{String,Union{Dict{String,String},String}}()
    end

    @testset "iquery" begin
        v, a, f = AllocationOpt.iquery()
        @test v == "indexers"
        @test f == ["id", "delegatedTokens", "stakedTokens", "lockedTokens"]
        @test a == Dict{String,Union{Dict{String,String},String,Int64}}(
            "first" => 1000,
            "where" => Dict("stakedTokens_gte" => "100000000000000000000000"),
        )
    end

    @testset "aquery" begin
        v, a, f = AllocationOpt.aquery()
        @test v == "allocations"
        @test f == ["allocatedTokens", "subgraphDeployment{ipfsHash}", "indexer{id}"]
        @test a == Dict{String,Union{Dict{String,String},String}}(
            "where" => Dict("status" => "Active")
        )
    end

    @testset "nquery" begin
        v, a, f = AllocationOpt.nquery()
        @test v == "graphNetwork"
        @test f == [
            "id",
            "totalSupply",
            "networkGRTIssuance",
            "epochLength",
            "totalTokensSignalled",
            "currentEpoch",
        ]
        @test a == Dict("id" => 1)
    end

    @testset "savenames" begin
        paths = (
            "mypath/indexer.csv",
            "mypath/allocation.csv",
            "mypath/subgraph.csv",
            "mypath/network.csv",
        )
        path = "mypath"
        vals = AllocationOpt.savenames(path)
        for (v, p) in zip(vals, paths)
            @test v == p
        end
    end

    @testset "data" begin
        @testset "from files" begin
            config = Dict("verbose" => false)
            apply(read_csv_success_patch) do
                i, a, s, n = AllocationOpt.data("", config)
                @test i.X == ["b", "c", "a", "c"]
            end
        end

        @testset "from network subgraph" begin
            config = Dict(
                "verbose" => false,
                "network_subgraph_endpoint" => "https://api.thegraph.com/subgraphs/name/graphprotocol/graph-network-mainnet",
            )
            apply(paginated_query_success_patch) do
                apply(query_success_patch) do
                    i, a, s, n = AllocationOpt.data(nothing, config)
                    @test i.stakedTokens == ["10", "20"]
                    @test s.signalledTokens == ["1", "2"]
                    @test a.allocatedTokens == ["1", "2"]
                    @test n.totalTokensSignalled == ["100"]
                end
            end
        end
    end
end
