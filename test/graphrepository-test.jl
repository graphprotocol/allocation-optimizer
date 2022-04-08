@testset "graphrepository.jl" begin
    url = "https://api.thegraph.com/subgraphs/name/graphprotocol/graph-network-mainnet"
    # repository = snapshot(url=url, indexer_query=nothing, subgraph_query=nothing)
    # network = network_issuance(url=url, network_id=nothing, network_query=nothing)

    alloc_df = optimize_indexer(;id="0xc60d0c8c74b5d3a33ed51c007ebae682490de261", grtgas=200.0, alloc_lifetime=14, whitelist=nothing, blacklist=nothing)

    println(alloc_df)
    @test true
end
