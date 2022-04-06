@testset "gascost.jl" begin
    # Estimate profit sans gas
    gas = 0.0
    allocs = Dict("0x001" => 1.0, "0x010" => 2.0)
    fake_repository = Repository(
        [Indexer("1x001", 10.0, 0.0, [Allocation("0x001", 2.0), Allocation("0x010", 8.0)])],
        [Subgraph("0x001", 6.0), Subgraph("0x010", 4.0)],
    )
    profit = estimated_profit(fake_repository, allocs, gas)
    @test profit == 2.8

    # Estimate profit with gas
    gas = 1.0
    profit = estimated_profit(fake_repository, allocs, gas)
    @test profit ≈ (-1.8)
end
