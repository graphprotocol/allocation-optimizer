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
        end

        @testset "subgraph" begin
            x = flextable([
                Dict("stakedTokens" => 1, "ipfsHash" => "Qma")
            ])
            @test AllocationOpt.ipfshash(Val(:subgraph), x) == ["Qma"]
        end

    end
end
