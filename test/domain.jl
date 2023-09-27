# Copyright 2022-, The Graph Foundation
# SPDX-License-Identifier: MIT

@testset "domain" begin
    @testset "togrt" begin
        @test AllocationOpt.togrt("1000000000000000000") == 1.0
    end

    @testset "accessors" begin
        @testset "network" begin
            n = flextable([
                Dict(
                    "id" => 1,
                    "networkGRTIssuancePerBlock" => 1,
                    "epochLength" => 28,
                    "totalTokensSignalled" => 2,
                    "currentEpoch" => 1,
                ),
            ])
            @test AllocationOpt.blockissuance(Val(:network), n) == 1
            @test AllocationOpt.blocksperepoch(Val(:network), n) == 28
            @test AllocationOpt.signal(Val(:network), n) == 2
            @test AllocationOpt.currentepoch(Val(:network), n) == 1
        end

        @testset "allocation" begin
            x = flextable([
                Dict(
                    "allocatedTokens" => 1,
                    "subgraphDeployment.ipfsHash" => "Qma",
                    "id" => "0xa",
                ),
            ])
            @test AllocationOpt.ipfshash(Val(:allocation), x) == ["Qma"]
            @test AllocationOpt.stake(Val(:allocation), x) == [1]
            @test AllocationOpt.id(Val(:allocation), x) == ["0xa"]
        end

        @testset "subgraph" begin
            x = flextable([
                Dict(
                    "stakedTokens" => 1,
                    "ipfsHash" => "Qma",
                    "signalledTokens" => 2,
                    "deniedAt" => 0,
                ),
            ])
            @test AllocationOpt.ipfshash(Val(:subgraph), x) == ["Qma"]
            @test AllocationOpt.stake(Val(:subgraph), x) == [1]
            @test AllocationOpt.signal(Val(:subgraph), x) == [2]
            @test AllocationOpt.deniedat(Val(:subgraph), x) == [0]
        end

        @testset "indexer" begin
            x = flextable([
                Dict("stakedTokens" => 10, "delegatedTokens" => 5, "lockedTokens" => 1)
            ])
            @test AllocationOpt.stake(Val(:indexer), x) == 10
            @test AllocationOpt.delegation(Val(:indexer), x) == 5
            @test AllocationOpt.locked(Val(:indexer), x) == 1
        end
    end

    @testset "availablestake" begin
        x = flextable([
            Dict("stakedTokens" => 10, "delegatedTokens" => 20, "lockedTokens" => 5)
        ])
        @test AllocationOpt.availablestake(Val(:indexer), x) == 25
    end

    @testset "frozen" begin
        a = flextable([
            Dict(
                "subgraphDeployment.ipfsHash" => "Qma",
                "allocatedTokens" => 5,
                "id" => "0xa",
            ),
            Dict(
                "subgraphDeployment.ipfsHash" => "Qmb",
                "allocatedTokens" => 10,
                "id" => "0xb",
            ),
        ])
        config = Dict("frozenlist" => ["Qma", "Qmb"])
        @test AllocationOpt.frozen(a, config) == 15
        config = Dict("frozenlist" => ["Qmb"])
        @test AllocationOpt.frozen(a, config) == 10
        config = Dict("frozenlist" => [])
        @test AllocationOpt.frozen(a, config) == 0
    end

    @testset "deniedzeroixs" begin
        s = flextable([
            Dict("ipfsHash" => "Qma", "signalledTokens" => 5.0, "deniedAt" => 0),
            Dict("ipfsHash" => "Qmb", "signalledTokens" => 10.0, "deniedAt" => 10),
            Dict("ipfsHash" => "Qmc", "signalledTokens" => 15.0, "deniedAt" => 0),
        ])
        @test AllocationOpt.deniedzeroixs(s) == [1, 3]
    end

    @testset "pinned" begin
        s = flextable([
            Dict("ipfsHash" => "Qma", "signalledTokens" => 5.0),
            Dict("ipfsHash" => "Qmb", "signalledTokens" => 10.0),
            Dict("ipfsHash" => "Qmc", "signalledTokens" => 15.0),
        ])
        config = Dict("pinnedlist" => ["Qma", "Qmb"])
        @test AllocationOpt.pinned(s, config) == [0.1, 0.1, 0.0]
        config = Dict("pinnedlist" => ["Qmb"])
        @test AllocationOpt.pinned(s, config) == [0.0, 0.1, 0.0]
        config = Dict("pinnedlist" => [])
        @test AllocationOpt.pinned(s, config) == [0.0, 0.0, 0.0]
    end

    @testset "allocatablesubgraphs" begin
        s = flextable([
            Dict("ipfsHash" => "Qma", "signalledTokens" => 5.0),
            Dict("ipfsHash" => "Qmb", "signalledTokens" => 10.0),
            Dict("ipfsHash" => "Qmc", "signalledTokens" => 15.0),
        ])

        config = Dict(
            "whitelist" => String[],
            "blacklist" => String[],
            "frozenlist" => String["Qma", "Qmb"],
            "pinnedlist" => String[],
            "min_signal" => 0.0,
        )
        fs = AllocationOpt.allocatablesubgraphs(s, config)
        @test AllocationOpt.ipfshash(Val(:subgraph), fs) == ["Qmc"]

        config = Dict(
            "whitelist" => String[],
            "blacklist" => String["Qma"],
            "frozenlist" => String["Qmb"],
            "pinnedlist" => String[],
            "min_signal" => 0.0,
        )
        fs = AllocationOpt.allocatablesubgraphs(s, config)
        @test AllocationOpt.ipfshash(Val(:subgraph), fs) == ["Qmc"]

        config = Dict(
            "whitelist" => String["Qmb", "Qmc"],
            "blacklist" => String[],
            "frozenlist" => String[],
            "pinnedlist" => String[],
            "min_signal" => 0.0,
        )
        fs = AllocationOpt.allocatablesubgraphs(s, config)
        @test AllocationOpt.ipfshash(Val(:subgraph), fs) == ["Qmb", "Qmc"]

        config = Dict(
            "whitelist" => String["Qmb", "Qmc"],
            "blacklist" => String["Qma"],
            "frozenlist" => String[],
            "pinnedlist" => String[],
            "min_signal" => 0.0,
        )
        fs = AllocationOpt.allocatablesubgraphs(s, config)
        @test AllocationOpt.ipfshash(Val(:subgraph), fs) == ["Qmb", "Qmc"]

        config = Dict(
            "whitelist" => String[],
            "blacklist" => String[],
            "frozenlist" => String[],
            "pinnedlist" => String[],
            "min_signal" => 0.0,
        )
        fs = AllocationOpt.allocatablesubgraphs(s, config)
        @test AllocationOpt.ipfshash(Val(:subgraph), fs) == ["Qma", "Qmb", "Qmc"]

        config = Dict(
            "whitelist" => String[],
            "blacklist" => String[],
            "frozenlist" => String[],
            "pinnedlist" => String[],
            "min_signal" => 7.0,
        )
        fs = AllocationOpt.allocatablesubgraphs(s, config)
        @test AllocationOpt.ipfshash(Val(:subgraph), fs) == ["Qmb", "Qmc"]

        config = Dict(
            "whitelist" => String["Qma"],
            "blacklist" => String[],
            "frozenlist" => String[],
            "pinnedlist" => String["Qmb"],
            "min_signal" => 0.0,
        )
        fs = AllocationOpt.allocatablesubgraphs(s, config)
        @test AllocationOpt.ipfshash(Val(:subgraph), fs) == ["Qma", "Qmb"]

        config = Dict(
            "whitelist" => String[],
            "blacklist" => String[],
            "frozenlist" => String[],
            "pinnedlist" => String["Qmb"],
            "min_signal" => 0.0,
        )
        fs = AllocationOpt.allocatablesubgraphs(s, config)
        @test AllocationOpt.ipfshash(Val(:subgraph), fs) == ["Qma", "Qmb", "Qmc"]
    end

    @testset "newtokenissuance" begin
        n = flextable([
            Dict(
                "id" => 1,
                "networkGRTIssuancePerBlock" => 1,
                "epochLength" => 1,
                "totalTokensSignalled" => 2,
                "currentEpoch" => 1,
            ),
        ])
        config = Dict("allocation_lifetime" => 0)
        @test AllocationOpt.newtokenissuance(n, config) == 0

        n = flextable([
            Dict(
                "id" => 1,
                "networkGRTIssuancePerBlock" => 1,
                "epochLength" => 0,
                "totalTokensSignalled" => 2,
                "currentEpoch" => 1,
            ),
        ])
        config = Dict("allocation_lifetime" => 1)
        @test AllocationOpt.newtokenissuance(n, config) == 0

        n = flextable([
            Dict(
                "id" => 1,
                "networkGRTIssuancePerBlock" => 0,
                "epochLength" => 1,
                "totalTokensSignalled" => 2,
                "currentEpoch" => 1,
            ),
        ])
        config = Dict("allocation_lifetime" => 1)
        @test AllocationOpt.newtokenissuance(n, config) == 0

        n = flextable([
            Dict(
                "id" => 1,
                "networkGRTIssuancePerBlock" => 1,
                "epochLength" => 1,
                "totalTokensSignalled" => 2,
                "currentEpoch" => 1,
            ),
        ])
        config = Dict("allocation_lifetime" => 1)
        @test AllocationOpt.newtokenissuance(n, config) == 1
    end

    @testset "indexingreward" begin
        @testset "scalar input" begin
            ψ = 0.0
            Ω = 1.0
            Φ = 1.0
            Ψ = 2.0
            x = 1.0
            @test AllocationOpt.indexingreward(x, Ω, ψ, Φ, Ψ) == 0.0

            ψ = 1.0
            Ω = 1.0
            Φ = 1.0
            Ψ = 2.0
            x = 1.0
            @test AllocationOpt.indexingreward(x, Ω, ψ, Φ, Ψ) == 0.25
        end

        @testset "vector input" begin
            ψ = [0.0, 1.0]
            Ω = [1.0, 1.0]
            Φ = 1.0
            Ψ = 2.0
            x = [1.0, 0.0]
            @test AllocationOpt.indexingreward(x, Ω, ψ, Φ, Ψ) == 0.0

            ψ = [0.0, 1.0]
            Ω = [1.0, 1.0]
            Φ = 1.0
            Ψ = 2.0
            x = [0.0, 1.0]
            @test AllocationOpt.indexingreward(x, Ω, ψ, Φ, Ψ) == 0.25

            ψ = [1.0, 1.0]
            Ω = [1.0, 1.0]
            Φ = 1.0
            Ψ = 2.0
            x = [1.0, 1.0]
            @test AllocationOpt.indexingreward(x, Ω, ψ, Φ, Ψ) == 0.5
        end

        @testset "specifying ixs" begin
            ixs = Int32[2]
            ψ = [0.0, 1.0]
            Ω = [1.0, 1.0]
            Φ = 1.0
            Ψ = 2.0
            x = [0.0, 1.0]
            @test AllocationOpt.indexingreward(ixs, x, Ω, ψ, Φ, Ψ) == 0.25

            ixs = Int32[1]
            ψ = [0.0, 1.0]
            Ω = [1.0, 1.0]
            Φ = 1.0
            Ψ = 2.0
            x = [0.0, 1.0]
            @test AllocationOpt.indexingreward(ixs, x, Ω, ψ, Φ, Ψ) == 0.0
        end
    end

    @testset "profit" begin
        @testset "individual input" begin
            r = 10
            g = 1
            @test AllocationOpt.profit(r, g) == 9

            r = 0
            g = 1
            @test AllocationOpt.profit(r, g) == 0
        end
    end
end
