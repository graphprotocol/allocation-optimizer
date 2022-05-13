using GraphQLClient

function verify_ipfshashes(xs::Vector{T}) where {T<:AbstractString}
    return all(map(x -> verify_ipfshash(x), xs))
end

function ipfshash_in(whitelist::Vector{T}, pinnedlist::Vector{T}) where {T<:AbstractString}
    return whitelist ∪ pinnedlist
end

function ipfshash_not_in(
    blacklist::Vector{T}, frozenlist::Vector{T}
) where {T<:AbstractString}
    return blacklist ∪ frozenlist
end

function frozen_stake(
    client::Client, id::AbstractString, frozenlist::Vector{T}
) where {T<:AbstractString}
    allocations_where_query::Dict{String,Union{String,Vector{String}}} = Dict(
        "status" => "Active", "indexer" => id
    )

    allocations_query = GQLQuery(
        Dict("where" => allocations_where_query),
        ["allocatedTokens", "subgraphDeployment{ ipfsHash }"],
    )
    allocations_data = query(client, "allocations"; query_args=allocations_query.args, output_fields=allocations_query.fields).data["allocations"]
    return sum(
        map(
            a -> togrt(a["allocatedTokens"]),
            filter(
                a -> (a["subgraphDeployment"]["ipfsHash"] in frozenlist), allocations_data
            ),
        ),
    )
end

function query_subgraphs(
    client::Client, ipfsin::Vector{T}, ipfs_notin::Vector{T}
) where {T<:AbstractString}
    subgraph_where_query::Dict{String,Union{String,Vector{String}}} = Dict(
        "signalledTokens_gte" => "1000000000000000000000"
    )
    if !isempty(ipfsin)
        subgraph_where_query["ipfsHash_in"] = ipfsin
    end
    if !isempty(ipfs_notin)
        subgraph_where_query["ipfsHash_not_in"] = ipfs_notin
    end
    subgraph_query = GQLQuery(
        Dict(
            "first" => 1000,
            "orderBy" => "signalledTokens",
            "orderDirection" => "desc",
            "where" => subgraph_where_query,
        ),
        ["id", "ipfsHash", "signalledTokens"],
    )
    subgraphs_data = query(client, "subgraphDeployments"; query_args=subgraph_query.args, output_fields=subgraph_query.fields).data["subgraphDeployments"]
    subgraphs = map(
        x -> SubgraphDeployment(x["id"], x["ipfsHash"], x["signalledTokens"]),
        subgraphs_data,
    )
    return subgraphs
end

function query_indexers(client::Client, subgraphs::Vector{SubgraphDeployment})
    allocations_where_query::Dict{String,Union{String,Vector{String}}} = Dict(
        "status" => "Active"
    )
    subgraph_ids = map(x -> x.id, subgraphs)
    allocations_where_query["subgraphDeployment_in"] = subgraph_ids
    allocations_query = GraphQLClient.directly_write_query_args(
        Dict("where" => allocations_where_query)
    )
    indexer_query = GQLQuery(
        Dict(
            "first" => 1000,
            "where" => Dict("stakedTokens_gte" => "100000000000000000000000"),
        ),
        [
            "id",
            "delegatedTokens",
            "stakedTokens",
            "allocations($allocations_query){allocatedTokens,createdAtEpoch,subgraphDeployment{ipfsHash}}",
        ],
    )
    indexers_data = query(client, "indexers"; query_args=indexer_query.args, output_fields=indexer_query.fields).data["indexers"]
    indexers = map(
        x -> Indexer(x["id"], x["delegatedTokens"], x["stakedTokens"], x["allocations"]),
        indexers_data,
    )
    return indexers
end

function query_networkparams(client::Client)
    # GraphNetworkParameters (network_id 1 is Ethereum mainnet)
    network_id = 1
    network_query = GQLQuery(
        Dict("id" => network_id),
        [
            "id",
            "totalSupply",
            "networkGRTIssuance",
            "epochLength",
            "totalTokensSignalled",
            "currentEpoch",
        ],
    )
    network_data = query(client, "graphNetwork"; query_args=network_query.args, output_fields=network_query.fields).data["graphNetwork"]
    network = GraphNetworkParameters(
        network_data["id"],
        network_data["totalSupply"],
        network_data["networkGRTIssuance"],
        network_data["epochLength"],
        network_data["totalTokensSignalled"],
        network_data["currentEpoch"],
    )
    return network
end

function gql_client()
    url = "https://api.thegraph.com/subgraphs/name/graphprotocol/graph-network-mainnet"
    client = Client(url)
    return client
end

function snapshot(
    client, ipfsin::Vector{T}, ipfs_notin::Vector{T}
) where {T<:AbstractString}
    subgraphs = query_subgraphs(client, ipfsin, ipfs_notin)
    indexers = query_indexers(client, subgraphs)
    network = query_networkparams(client)

    # Make repository
    repository = Repository(indexers, subgraphs)
    return repository, network
end
