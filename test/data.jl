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
end
