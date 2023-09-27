read_csv_success_patch = @patch function TheGraphData.read(f; kwargs...)
    if f ∈ ("indexer.csv", "allocation.csv", "subgraph.csv", "network.csv")
        @info "TheGraphData.read stub => simulating success"
        return CSV.File(IOBuffer("X\nb\nc\na\nc"))
    else
        @info "TheGraphData.read stub => simulating failure"
        throw(ArgumentError("TheGraphData.read stub => simulating failure"))
    end
end

paginated_query_success_patch = @patch function paginated_query(v, a, f)
    if v == "subgraphDeployments"
        @info "paginated query stub ==> simulating subgraphs"
        return [
            Dict(
                "ipfsHash" => "Qma",
                "signalledTokens" => "1",
                "stakedTokens" => "1",
                "deniedAt" => 0,
            ),
            Dict(
                "ipfsHash" => "Qmb",
                "signalledTokens" => "2",
                "stakedTokens" => "2",
                "deniedAt" => 0,
            ),
        ]
    end
    if v == "allocations"
        @info "paginated query stub ==> simulating allocations"
        return [
            Dict(
                "subgraphDeployment" => Dict("ipfsHash" => "Qma"),
                "id" => "0xa",
                "allocatedTokens" => "1",
            ),
        ]
    end
end

query_success_patch = @patch function query(v, a, f)
    if v == "indexer"
        @info "query stub ==> simulating indexers"
        return [
            Dict("delegatedTokens" => "1", "stakedTokens" => "10", "lockedTokens" => "100")
        ]
    end
    if v == "graphNetwork"
        @info "query stub ==> network parameters"
        return [
            Dict(
                "totalTokensSignalled" => "100",
                "currentEpoch" => 1,
                "id" => "1",
                "networkGRTIssuancePerBlock" => "100",
                "epochLength" => 1,
            ),
        ]
    end
end

write_success_patch = @patch function TheGraphData.write(p, d)
    println("TheGraphData.write stub => simulating success")
    return p
end

writejson_success_patch = @patch function JSON.print(io, s)
    println("JSON.print stub => simulating success")
    return s
end

mutate_success_patch = @patch function mutate(v, a; kwargs...)
    println("mutate stub ==> simulating queueActions")
    return [Dict(v => a["actions"])]
end
