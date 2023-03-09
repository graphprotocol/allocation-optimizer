# Copyright 2022-, The Graph Foundation
# SPDX-License-Identifier: MIT

@testset "domain" begin
    @testset "togrt" begin
        @test AllocationOpt.togrt("1000000000000000000") == 1.0
    end
end
