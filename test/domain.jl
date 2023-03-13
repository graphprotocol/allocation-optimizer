# Copyright 2022-, The Graph Foundation
# SPDX-License-Identifier: MIT

@testset "domain" begin
    @testset "togrt" begin
        @test AllocationOpt.togrt("1000000000000000000") == 1.0
    end

    @testset "accessors" begin

        @testset "allocation" begin
            x = flextable([
                Dict("allocatedTokens" => 1, "subgraphDeployment.ipfsHash" => "Qma")
            ])
            @test AllocationOpt.ipfshash(Val(:allocation), x) == ["Qma"]
            @test AllocationOpt.stake(Val(:allocation), x) == [1]
        end

        @testset "subgraph" begin
            x = flextable([Dict("stakedTokens" => 1, "ipfsHash" => "Qma", "signalledTokens" => 2)])
            @test AllocationOpt.ipfshash(Val(:subgraph), x) == ["Qma"]
            @test AllocationOpt.stake(Val(:subgraph), x) == [1]
            @test AllocationOpt.signal(Val(:subgraph), x) == [2]
        end

        @testset "indexer" begin
            x = flextable([Dict("stakedTokens" => 10, "delegatedTokens" => 5, "lockedTokens" => 1)])
            @test AllocationOpt.stake(Val(:indexer), x) == 10
            @test AllocationOpt.delegation(Val(:indexer), x) == 5
            @test AllocationOpt.locked(Val(:indexer), x) == 1
        end

    end

    @testset "frozen" begin
        a = flextable([
            Dict("subgraphDeployment.ipfsHash" => "Qma", "allocatedTokens" => 5),
            Dict("subgraphDeployment.ipfsHash" => "Qmb", "allocatedTokens" => 10),
        ])
        config = Dict("frozenlist" => ["Qma", "Qmb"])
        @test AllocationOpt.frozen(a, config) == 15
        config = Dict("frozenlist" => ["Qmb"])
        @test AllocationOpt.frozen(a, config) == 10
        config = Dict("frozenlist" => [])
        @test AllocationOpt.frozen(a, config) == 0
    end

    @testset "pinned" begin
        config = Dict("pinnedlist" => ["Qma", "Qmb"])
        @test AllocationOpt.pinned(config) == 0.2
        config = Dict("pinnedlist" => ["Qmb"])
        @test AllocationOpt.pinned(config) == 0.1
        config = Dict("pinnedlist" => [])
        @test AllocationOpt.pinned(config) == 0.0
    end

end
