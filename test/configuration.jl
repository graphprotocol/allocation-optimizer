# Copyright 2022-, The Graph Foundation
# SPDX-License-Identifier: MIT

@testset "configuration" begin
    @testset "configuredefaults!" begin
        config = Dict{String,Any}()
        @test_throws AssertionError AllocationOpt.configuredefaults!(config)

        config = Dict{String,Any}("id" => "a")
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
        @test config["min_signal"] == 100
        @test config["max_allocations"] == 10
        @test config["num_reported_options"] == 1
        @test config["execution_mode"] == "none"
        @test isnothing(config["indexer_url"])
        @test !config["verbose"]
        @test config["opt_mode"] == "optimal"
        @test config["protocol_network"] == "mainnet"
        @test config["syncing_networks"] == ["mainnet"]

        config = Dict{String,Any}("id" => "a", "gas" => 0)
        config = AllocationOpt.configuredefaults!(config)
        @test config["gas"] == 0
        @test !config["verbose"]
    end

    @testset "readconfig" begin
        # Test roughly equivalent from test of TOML.jl parsefile
        dict = Dict{String,Any}("a" => 1)
        info = "a = 1"
        path, io = mktemp()
        write(io, info)
        close(io)
        val = AllocationOpt.readconfig(path)
        @test val == dict
    end

    @testset "formatconfig!" begin
        config = Dict("id" => "0xA")
        @test AllocationOpt.formatconfig!(config)["id"] == "0xa"
    end
end
