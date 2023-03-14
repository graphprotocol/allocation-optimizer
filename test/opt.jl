# Copyright 2022-, The Graph Foundation
# SPDX-License-Identifier: MIT

@testset "opt" begin
    @testset "optimizeanalytic" begin
        Ω = [1.0, 1.0]
        ψ = [10.0, 10.0]
        σ = 5.0
        @test isapprox(AllocationOpt.optimizeanalytic(Ω, ψ, σ), [2.5, 2.5]; atol=0.1)

        Ω = [1.0, 1.0]
        ψ = [0.0, 10.0]
        σ = 5.0
        @test isapprox(AllocationOpt.optimizeanalytic(Ω, ψ, σ), [0.0, 5.0]; atol=0.1)

        Ω = [1.0, 10000.0]
        ψ = [10.0, 10.0]
        σ = 5.0
        @test isapprox(AllocationOpt.optimizeanalytic(Ω, ψ, σ), [5.0, 0.0]; atol=0.1)
    end
end
