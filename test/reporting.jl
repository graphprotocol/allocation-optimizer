# Copyright 2022-, The Graph Foundation
# SPDX-License-Identifier: MIT

@testset "reporting" begin
    @testset "groupunique" begin
        x = [1, 2, 1, 3, 2, 3]
        ixs = AllocationOpt.groupunique(x)
        @test ixs[[1]] == [1, 3]
        @test ixs[[2]] == [2, 5]
        @test ixs[[3]] == [4, 6]
    end
    @testset "bestprofitpernz" begin
        ixs = Dict([1] => [1], [2] => [2])
        ps = [[2.5 5.0]; [2.5 1.0]]
        popts = AllocationOpt.bestprofitpernz.(values(ixs), Ref(ps))
        @test popts[1] == (; :profit => 5.0, :index => 1)
        @test popts[2] == (; :profit => 6.0, :index => 2)

        ixs = Dict([1] => [1, 2])
        ps = [[2.5 5.0]; [2.5 1.0]]
        popts = AllocationOpt.bestprofitpernz.(values(ixs), Ref(ps))
        @test popts[1] == (; :profit => 6.0, :index => 2)
    end
    @testset "sortprofits!" begin
        popts = [
            (; :profit => 5.0, :index => 2),
            (; :profit => 6.0, :index => 1)
        ]
        @test AllocationOpt.sortprofits!(popts)[1][:profit] == 6.0
    end
    @testset "reportingtable" begin
        s = flextable([
            Dict("stakedTokens" => "1", "signalledTokens" => "2", "ipfsHash" => "Qma"),
            Dict("stakedTokens" => "2", "signalledTokens" => "1", "ipfsHash" => "Qmb"),
        ])
        xs = [[2.5 5.0]; [2.5 0.0]]
        ps = [[3.0 5.0]; [3.0 0.0]]
        i = 2
        t = AllocationOpt.reportingtable(s, xs, ps, i)
        @test t.ipfshash ==  ["Qma"]
        @test t.amount == [5.0]
        @test t.profit == [5.0]
    end
    @testset "strategydict" begin
        popts = [
            (; :profit => 6.0, :index => 1),
            (; :profit => 5.0, :index => 2)
        ]
        xs = [[2.5 5.0]; [2.5 0.0]]
        profits = [[3.0 5.0]; [3.0 0.0]]
        nonzeros = [2, 1]
        fs = flextable([
            Dict("stakedTokens" => "1", "signalledTokens" => "0", "ipfsHash" => "Qma"),
            Dict("stakedTokens" => "2", "signalledTokens" => "0", "ipfsHash" => "Qmb"),
        ])
        out = AllocationOpt.strategydict.(
            popts, Ref(xs), Ref(nonzeros), Ref(fs), Ref(profits)
        )
        expected = [
            Dict(
                "num_allocations" => 2,
                "profit" => 6.0,
                "allocations" => [
                    Dict(
                        "deploymentID" => "Qma",
                        "allocationAmount" => "2.5",
                        "profit" => 3.0,
                    )
                    Dict(
                        "deploymentID" => "Qmb",
                        "allocationAmount" => "2.5",
                        "profit" => 3.0,
                    )
                ]
            )
            Dict("num_allocations" => 1,
                "profit" => 5.0,
                "allocations" => [
                    Dict(
                        "deploymentID" => "Qma",
                        "allocationAmount" => "5",
                        "profit" => 5.0
                    )
                ]
            )
        ]
        @test out == expected
    end

    @testset "writejson" begin
        output = "{\"strategies\":[{\"num_allocations\":2,\"profit\":6.0,\"allocations\":[{\"allocationAmount\":\"2.5\",\"profit\":3.0,\"deploymentID\":\"Qma\"},{\"allocationAmount\":\"2.5\",\"profit\":3.0,\"deploymentID\":\"Qmb\"}]},{\"num_allocations\":1,\"profit\":5.0,\"allocations\":[{\"allocationAmount\":\"5\",\"profit\":5.0,\"deploymentID\":\"Qma\"}]}]}"
        config = Dict("writedir" => ".")
        apply(writejson_success_patch) do
            p = AllocationOpt.writejson(output, config)
            @test p == "./report.json"
        end
        rm("./report.json")
    end

    @testset "unallocate" begin
        a = flextable([
            Dict("subgraphDeployment.ipfsHash" => "Qma", "id" => "0xa")
        ])
        t = flextable([
            Dict("amount" => "2", "profit" => "0", "ipfshash" => "Qmb"),
        ])

        config = Dict("frozenlist" => String[])
        cfg = Dict("frozenlist" => ["Qma"])

        @testset "none" begin
            @inferred AllocationOpt.unallocate(Val(:none), a, t, config)
        end

        @testset "rules" begin
            @inferred AllocationOpt.unallocate(Val(:rules), a, t, config)
            out = AllocationOpt.unallocate(Val(:rules), a, t, config)
            @test out == ["\e[0mgraph indexer rules stop Qma"]

            out = AllocationOpt.unallocate(Val(:rules), a, t, cfg)
            @test isempty(out)
        end

        @testset "actionqueue" begin
            apply(mutate_success_patch) do
                @inferred AllocationOpt.unallocate(Val(:actionqueue), a, t, config)
            end

            apply(mutate_success_patch) do
                out = AllocationOpt.unallocate(Val(:actionqueue), a, t, config)
                @test out == [
                    Dict(
                        "status" => AllocationOpt.queued,
                        "type" => AllocationOpt.unallocateaction,
                        "allocation" => "0xa",
                        "ipfshash" => "Qma",
                        "user" => "AllocationOpt",
                        "reason" => "AllocationOpt",
                        "priority" => 0,
                    )
                ]
            end

            apply(mutate_success_patch) do
                out = AllocationOpt.unallocate(Val(:actionqueue), a, t, cfg)
                @test isempty(out)
            end
        end
    end

    @testset "reallocate" begin
        a = flextable([
            Dict("subgraphDeployment.ipfsHash" => "Qma", "id" => "0xa")
        ])
        t = flextable([
            Dict("amount" => "1", "profit" => "0", "ipfshash" => "Qma"),
            Dict("amount" => "2", "profit" => "0", "ipfshash" => "Qmb"),
        ])
        config = Dict()

        @testset "none" begin
            @inferred AllocationOpt.reallocate(Val(:none), a, t, config)
        end

        @testset "rules" begin
            @inferred AllocationOpt.reallocate(Val(:rules), a, t, config)
            out = AllocationOpt.reallocate(Val(:rules), a, t, config)
            @test out == ["\e[0mgraph indexer rules stop Qma\n\e[1m\e[38;2;255;0;0;249mCheck allocation status being closed before submitting: \e[0mgraph indexer rules set Qma decisionBasis always allocationAmount 1"]
        end

        @testset "actionqueue" begin
            apply(mutate_success_patch) do
                @inferred AllocationOpt.reallocate(Val(:actionqueue), a, t, config)
            end

            apply(mutate_success_patch) do
                out = AllocationOpt.reallocate(Val(:actionqueue), a, t, config)
                @test out == [
                    Dict(
                        "status" => AllocationOpt.queued,
                        "type" => AllocationOpt.reallocateaction,
                        "allocation" => "0xa",
                        "ipfshash" => "Qma",
                        "amount" => "1",
                        "user" => "AllocationOpt",
                        "reason" => "Expected profit: 0",
                        "priority" => 0,
                    )
                ]
            end
        end
    end

    @testset "allocate" begin
        a = flextable([
            Dict("subgraphDeployment.ipfsHash" => "Qma", "id" => "0xa")
        ])
        t = flextable([
            Dict("amount" => "1", "profit" => "0", "ipfshash" => "Qma"),
            Dict("amount" => "2", "profit" => "0", "ipfshash" => "Qmb"),
        ])
        config = Dict()

        @testset "none" begin
            @inferred AllocationOpt.allocate(Val(:none), a, t, config)
        end

        @testset "rules" begin
            @inferred AllocationOpt.allocate(Val(:rules), a, t, config)
            out = AllocationOpt.allocate(Val(:rules), a, t, config)
            @test out == ["\e[0mgraph indexer rules set Qmb decisionBasis always allocationAmount 2"]
        end

        @testset "actionqueue" begin
            apply(mutate_success_patch) do
                @inferred AllocationOpt.allocate(Val(:actionqueue), a, t, config)
            end

            apply(mutate_success_patch) do
                out = AllocationOpt.allocate(Val(:actionqueue), a, t, config)
                @test out == [
                    Dict(
                        "status" => AllocationOpt.queued,
                        "type" => AllocationOpt.allocateaction,
                        "ipfshash" => "Qmb",
                        "amount" => "2",
                        "user" => "AllocationOpt",
                        "reason" => "Expected profit: 0",
                        "priority" => 0,
                    )
                ]
            end
        end
    end
end
