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
                        "allocationAmount" => 2.5,
                        "profit" => 3.0,
                    )
                    Dict(
                        "deploymentID" => "Qmb",
                        "allocationAmount" => 2.5,
                        "profit" => 3.0,
                    )
                ]
            )
            Dict("num_allocations" => 1,
                "profit" => 5.0,
                "allocations" => [
                    Dict(
                        "deploymentID" => "Qma",
                        "allocationAmount" => 5.0,
                        "profit" => 5.0
                    )
                ]
            )
        ]
        @test out == expected
    end
end
