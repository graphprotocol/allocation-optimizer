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
        id = "0xa"
        v, a, f = AllocationOpt.iquery(id)
        @test v == "indexer"
        @test f == ["delegatedTokens", "stakedTokens", "lockedTokens"]
        @test a == Dict{String,Union{Dict{String,String},String,Int64}}("id" => id)
    end

    @testset "aquery" begin
        config = Dict("id" => "0xa")
        v, a, f = AllocationOpt.aquery(config["id"])
        @test v == "allocations"
        @test f == ["allocatedTokens", "id", "subgraphDeployment{ipfsHash}"]
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

    @testset "correcttypes!" begin
        @testset "indexer" begin
            i = flextable([
                Dict("stakedTokens" => "1", "delegatedTokens" => "0", "lockedTokens" => "0")
            ])
            AllocationOpt.correcttypes!(Val(:indexer), i)
            @test i.stakedTokens == [1e-18]
            @test i.delegatedTokens == [0]
            @test i.lockedTokens == [0]
        end

        @testset "subgraph" begin
            s = flextable([
                Dict("stakedTokens" => "1", "signalledTokens" => "0", "ipfsHash" => "Qma"),
                Dict("stakedTokens" => "2", "signalledTokens" => "0", "ipfsHash" => "Qmb"),
                Dict("stakedTokens" => "3", "signalledTokens" => "0", "ipfsHash" => "Qmc"),
            ])
            AllocationOpt.correcttypes!(Val(:subgraph), s)
            @test s.stakedTokens == [1e-18, 2e-18, 3e-18]
            @test s.signalledTokens == [0, 0, 0]
            @test s.ipfsHash == ["Qma", "Qmb", "Qmc"]
        end

        @testset "allocation" begin
            a = flextable([
                Dict("allocatedTokens" => "1", "subgraphDeployment.ipfsHash" => "Qma", "id" => "0xa"),
                Dict("allocatedTokens" => "2", "subgraphDeployment.ipfsHash" => "Qmb", "id" => "0xb"),
                Dict("allocatedTokens" => "3", "subgraphDeployment.ipfsHash" => "Qmc", "id" => "0xc"),
            ])
            AllocationOpt.correcttypes!(Val(:allocation), a)
            @test a.allocatedTokens == [1e-18, 2e-18, 3e-18]
            @test getproperty(a, Symbol("subgraphDeployment.ipfsHash")) ==
                ["Qma", "Qmb", "Qmc"]
        end

        @testset "network" begin
            n = flextable([
                Dict(
                    "totalTokensSignalled" => "100",
                    "currentEpoch" => 1,
                    "totalSupply" => "100",
                    "id" => "1",
                    "networkGRTIssuance" => "100",
                    "epochLength" => 1,
                ),
            ])
            AllocationOpt.correcttypes!(Val(:network), n)
            @test n.totalTokensSignalled == [1e-16]
            @test n.currentEpoch == [1]
            @test n.totalSupply == [1e-16]
            @test n.id == ["1"]
            @test n.networkGRTIssuance == [1e-16]
            @test n.epochLength == [1]
        end

        @testset "all" begin
            i = flextable([
                Dict("stakedTokens" => "1", "delegatedTokens" => "0", "lockedTokens" => "0")
            ])
            s = flextable([
                Dict("stakedTokens" => "1", "signalledTokens" => "0", "ipfsHash" => "Qma"),
                Dict("stakedTokens" => "2", "signalledTokens" => "0", "ipfsHash" => "Qmb"),
                Dict("stakedTokens" => "3", "signalledTokens" => "0", "ipfsHash" => "Qmc"),
            ])
            a = flextable([
                Dict("allocatedTokens" => "1", "subgraphDeployment.ipfsHash" => "Qma", "id" => "0xa"),
                Dict("allocatedTokens" => "2", "subgraphDeployment.ipfsHash" => "Qmb", "id" => "0xb"),
                Dict("allocatedTokens" => "3", "subgraphDeployment.ipfsHash" => "Qmc", "id" => "0xc"),
            ])
            n = flextable([
                Dict(
                    "totalTokensSignalled" => "100",
                    "currentEpoch" => 1,
                    "totalSupply" => "100",
                    "id" => "1",
                    "networkGRTIssuance" => "100",
                    "epochLength" => 1,
                ),
            ])
            i, a, s, n = AllocationOpt.correcttypes!(i, a, s, n)
            @test i.stakedTokens == [1e-18]
            @test i.delegatedTokens == [0]
            @test i.lockedTokens == [0]
            @test s.stakedTokens == [1e-18, 2e-18, 3e-18]
            @test s.signalledTokens == [0, 0, 0]
            @test s.ipfsHash == ["Qma", "Qmb", "Qmc"]
            @test a.allocatedTokens == [1e-18, 2e-18, 3e-18]
            @test getproperty(a, Symbol("subgraphDeployment.ipfsHash")) ==
                ["Qma", "Qmb", "Qmc"]
            @test n.totalTokensSignalled == [1e-16]
            @test n.currentEpoch == [1]
            @test n.totalSupply == [1e-16]
            @test n.id == ["1"]
            @test n.networkGRTIssuance == [1e-16]
            @test n.epochLength == [1]
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
                    @test i.stakedTokens == [1e-17]
                    @test s.signalledTokens == [1e-18, 2e-18]
                    @test s.stakedTokens == [0.0, 2e-18]
                    @test n.totalTokensSignalled == [1e-16]
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

    @testset "subtractindexer!" begin
        s = flextable([
            Dict("ipfsHash" => "Qmb", "stakedTokens" => 20),
            Dict("ipfsHash" => "Qma", "stakedTokens" => 10),
            Dict("ipfsHash" => "Qmc", "stakedTokens" => 5),
        ])
        a = flextable([
            Dict("allocatedTokens" => 5, "subgraphDeployment.ipfsHash" => "Qma", "id" => "0xa"),
            Dict("allocatedTokens" => 10, "subgraphDeployment.ipfsHash" => "Qmb", "id" => "0xb"),
        ])
        a, s = AllocationOpt.subtractindexer!(a, s)
        @test s.stakedTokens == [5, 10, 5]
    end
end
