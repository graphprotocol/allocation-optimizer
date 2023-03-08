# Copyright 2022-, The Graph Foundation
# SPDX-License-Identifier: MIT

@testset "configuration" begin
    @testset "configuredefaults!" begin
        config = Dict()
        config = AllocationOpt.configuredefaults!(config)
        @test isnothing(config["readdir"])
        @test config["writedir"] == "."
        @test config["network_subgraph_endpoint"] ==
            "https://api.thegraph.com/subgraphs/name/graphprotocol/graph-network-mainnet"
        @test config["whitelist"] == String[]
        @test config["blacklist"] == String[]
        @test config["frozenlist"] == String[]
        @test config["pinnedlist"] == String[]
        @test config["allocation_lifetime"] == 28
        @test config["gas"] == 100
        @test config["min_signal"] == 1000
        @test config["max_allocations"] == 10
        @test !config["verbose"]

        config = Dict{String,Any}("gas" => 0)
        config = AllocationOpt.configuredefaults!(config)
        @test config["gas"] == 0
        @test !config["verbose"]
    end
end
