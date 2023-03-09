read_csv_success_patch = @patch function TheGraphData.read(f; kwargs...)
    @info "TheGraphData.read stub => simulating success"
    return CSV.File(IOBuffer("X\nb\nc\na\nc"))
end

paginated_query_success_patch = @patch function paginated_query(v, a, f)
    if v == "subgraphDeployments"
        @info "query stub ==> simulating subgraphs"
        return [
            Dict("ipfsHash" => "Qma", "signalledTokens" => "1"),
            Dict("ipfsHash" => "Qmb", "signalledTokens" => "2"),
        ]
    end
    if v == "indexers"
        @info "query stub ==> simulating indexers"
        return [
            Dict(
                "id" => "0xa",
                "delegatedTokens" => "1",
                "stakedTokens" => "10",
                "lockedTokens" => "100",
            ),
            Dict(
                "id" => "0xb",
                "delegatedTokens" => "2",
                "stakedTokens" => "20",
                "lockedTokens" => "200",
            ),
        ]
    end
    if v == "allocations"
        @info "query stub ==> simulating allocations"
        return [
            Dict(
                "indexer" => Dict("id" => "0xa"),
                "subgraphDeployment" => Dict("ipfsHash" => "Qma"),
                "allocatedTokens" => "1",
            ),
            Dict(
                "indexer" => Dict("id" => "0xb"),
                "subgraphDeployment" => Dict("ipfsHash" => "Qmb"),
                "allocatedTokens" => "2",
            ),
        ]
    end
end

query_success_patch = @patch function query(v, a, f)
    @info "query stub ==> network parameters"
    return [
        Dict(
            "totalTokensSignalled" => "100",
            "currentEpoch" => 1,
            "totalSupply" => "100",
            "id" => "1",
            "networkGRTIssuance" => "100",
            "epochLength" => 1,
        ),
    ]
end
