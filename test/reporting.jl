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
end
