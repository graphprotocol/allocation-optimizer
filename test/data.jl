# Copyright 2022-, The Graph Foundation
# SPDX-License-Identifier: MIT

@testset "data" begin
    @testset "squery" begin
        v, a, f = AllocationOpt.squery()
        @test v == "subgraphDeployments"
        @test f == ["ipfsHash", "signalledTokens", "stakedTokens"]
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
        config = Dict("id" => "0xa")
        v, a, f = AllocationOpt.aquery(config["id"])
        @test v == "allocations"
        @test f == ["allocatedTokens", "subgraphDeployment{ipfsHash}"]
        @test a == Dict{String,Union{Dict{String,String},String}}(
            "where" => Dict("status" => "Active", "indexer" => config["id"])
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

    @testset "read" begin
        @testset "from files" begin
            config = Dict("verbose" => false, "readdir" => "")
            apply(read_csv_success_patch) do
                i, a, s, n = AllocationOpt.read(config)
                @test i.X == ["b", "c", "a", "c"]
            end
        end

        @testset "from network subgraph" begin
            config = Dict(
                "id" => "0xa",
                "verbose" => false,
                "network_subgraph_endpoint" => "https://api.thegraph.com/subgraphs/name/graphprotocol/graph-network-mainnet",
                "readdir" => nothing,
            )
            apply(paginated_query_success_patch) do
                apply(query_success_patch) do
                    i, a, s, n = AllocationOpt.read(config)
                    @test i.stakedTokens == ["10", "20"]
                    @test s.signalledTokens == ["1", "2"]
                    @test s.stakedTokens == ["1", "2"]
                    @test a.allocatedTokens == ["1"]
                    @test n.totalTokensSignalled == ["100"]
                end
            end
        end
    end

    @testset "write" begin
        config = Dict("verbose" => false, "writedir" => "tmp")
        t = flextable([Dict("foo" => 1, "bar" => 2)])
        i, a, s, n = repeat([t], 4)
        apply(write_success_patch) do
            ps = AllocationOpt.write(i, a, s, n, config)
            @test ps == [
                "tmp/indexer.csv",
                "tmp/allocation.csv",
                "tmp/subgraph.csv",
                "tmp/network.csv",
            ]
        end
    end

    @testset "correcttypes!" begin
        @testset "indexer" begin
            i = flextable([
                Dict(
                    "stakedTokens" => "1",
                    "delegatedTokens" => "0",
                    "id" => "0xa",
                    "lockedTokens" => "0",
                ),
                Dict(
                    "stakedTokens" => "1",
                    "delegatedTokens" => "0",
                    "id" => "0xb",
                    "lockedTokens" => "0",
                ),
                Dict(
                    "stakedTokens" => "1",
                    "delegatedTokens" => "0",
                    "id" => "0xc",
                    "lockedTokens" => "0",
                ),
            ])
            AllocationOpt.correcttypes!(Val(:indexer), i)
            @test i.stakedTokens == [1e-18, 1e-18, 1e-18]
            @test i.delegatedTokens == [0, 0, 0]
            @test i.id == ["0xa", "0xb", "0xc"]
            @test i.lockedTokens == [0, 0, 0]
        end
        @testset "subgraph" begin
            s = flextable([
                Dict(
                    "stakedTokens" => "1",
                    "signalledTokens" => "0",
                    "ipfsHash" => "Qma",
                ),
                Dict(
                    "stakedTokens" => "2",
                    "signalledTokens" => "0",
                    "ipfsHash" => "Qmb",
                ),
                Dict(
                    "stakedTokens" => "3",
                    "signalledTokens" => "0",
                    "ipfsHash" => "Qmc",
                ),
            ])
            AllocationOpt.correcttypes!(Val(:subgraph), s)
            @test s.stakedTokens == [1e-18, 2e-18, 3e-18]
            @test s.signalledTokens == [0, 0, 0]
            @test s.ipfsHash == ["Qma", "Qmb", "Qmc"]
        end
        @testset "allocation" begin
            a = flextable([
                Dict(
                    "allocatedTokens" => "1",
                    "subgraphDeployment.ipfsHash" => "Qma",
                ),
                Dict(
                    "allocatedTokens" => "2",
                    "subgraphDeployment.ipfsHash" => "Qmb",
                ),
                Dict(
                    "allocatedTokens" => "3",
                    "subgraphDeployment.ipfsHash" => "Qmc",
                ),
            ])
            AllocationOpt.correcttypes!(Val(:allocation), a)
            @test a.allocatedTokens == [1e-18, 2e-18, 3e-18]
            @test getproperty(a, Symbol("subgraphDeployment.ipfsHash"))== ["Qma", "Qmb", "Qmc"]
        end
    end
end
