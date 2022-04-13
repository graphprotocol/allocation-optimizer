using GraphQLClient

export Allocation, Indexer, Subgraph, Network, GQLQuery, Repository, snapshot, network_issuance

function togrt(x)::Float64
    return parse(Float64, x) / 1e18
end

struct GQLQuery
    args::Dict{String,Any}
    fields::Vector{String}
end

struct Allocation
    id::String
    amount::Float64
    created_at_epoch::Int64

    Allocation(id, amount::String, created_at_epoch) = new(id, togrt(amount), created_at_epoch)
    Allocation(id, amount::Float64, created_at_epoch) = new(id, amount, created_at_epoch)
end

struct Indexer
    id::String
    delegation::Float64
    stake::Float64
    allocations::Vector{Allocation}

    function Indexer(id, delegation::String, stake::String, allocation)
        return new(
            id,
            togrt(delegation),
            togrt(stake),
            map(
                x -> Allocation(x["subgraphDeployment"]["id"], x["allocatedTokens"], x["createdAtEpoch"]),
                allocation,
            ),
        )
    end
    function Indexer(id, delegation::Float64, stake::Float64, allocation)
        return new(id, delegation, stake, allocation)
    end
end

struct Subgraph
    id::String
    signal::Float64

    Subgraph(id, signal::String) = new(id, togrt(signal))
    Subgraph(id, signal::Float64) = new(id, signal)
end

struct Repository
    indexers::Vector{Indexer}
    subgraphs::Vector{Subgraph}
end

struct Network
    id::String
    principle_supply::Float64
    issuance_rate_per_block::Float64
    block_per_epoch::Int
    total_tokens_signalled::Float64
    current_epoch::Int

    Network(id, principle_supply::String, issuance_rate_per_block::String, block_per_epoch::Int, total_tokens_signalled::String, current_epoch::Int) = 
        new(id, togrt(principle_supply), togrt(issuance_rate_per_block), block_per_epoch, togrt(total_tokens_signalled), current_epoch)
    Network(id, principle_supply::Float64, issuance_rate_per_block::Float64, block_per_epoch::Int, total_tokens_signalled::Float64, current_epoch::Int) = 
        new(id, principle_supply, issuance_rate_per_block, block_per_epoch, total_tokens_signalled, current_epoch)
end

function snapshot(;
    url::String,
    indexer_query::Union{Nothing,GQLQuery},
    subgraph_query::Union{Nothing,GQLQuery},
)
    client = Client(url)

    # Subgraphs
    if isnothing(subgraph_query)
        subgraph_query = GQLQuery(
            Dict(
                "first" => 1000, "orderBy" => "signalledTokens", "orderDirection" => "desc"
            ),
            ["id", "signalledTokens"],
        )
    end
    subgraphs_data = query(client, "subgraphDeployments"; query_args=subgraph_query.args, output_fields=subgraph_query.fields).data["subgraphDeployments"]
    subgraphs = map(x -> Subgraph(x["id"], x["signalledTokens"]), subgraphs_data)

    # Indexers
    if isnothing(indexer_query)
        indexer_query = GQLQuery(
            Dict(
                "first" => 1000,
                "where" => Dict("stakedTokens_gte" => "100000000000000000000000"),
            ),
            [
                "id",
                "delegatedTokens",
                "stakedTokens",
                "allocations(where: {status:\"Active\"}){allocatedTokens,createdAtEpoch,subgraphDeployment{id}}",
            ],
        )
    end
    indexers_data = query(client, "indexers"; query_args=indexer_query.args, output_fields=indexer_query.fields).data["indexers"]
    indexers = map(
        x -> Indexer(x["id"], x["delegatedTokens"], x["stakedTokens"], x["allocations"]),
        indexers_data,
    )

    # Make repository
    repository = Repository(indexers, subgraphs)
    return repository
end

function network_issuance(;
    url::String,
    network_id::Union{Nothing,Int},
    network_query::Union{Nothing,GQLQuery},
)
    client = Client(url)

    if isnothing(network_query)
        network_query =  GQLQuery(
            Dict(
                "id" => isnothing(network_id) ? 1 : network_id,
            ),
            ["id", "totalSupply", "networkGRTIssuance", "epochLength", "totalTokensSignalled", "currentEpoch"]
        )
    end
    network_data = query(client, "graphNetwork"; query_args=network_query.args, output_fields=network_query.fields).data["graphNetwork"]
    Network(network_data["id"], network_data["totalSupply"], network_data["networkGRTIssuance"], network_data["epochLength"], network_data["totalTokensSignalled"], network_data["currentEpoch"])
end
