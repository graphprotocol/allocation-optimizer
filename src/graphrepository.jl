using GraphQLClient

export Allocation, Indexer, Subgraph, GQLQuery, Repository, snapshot

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

    Allocation(id, amount::String) = new(id, togrt(amount))
    Allocation(id, amount::Float64) = new(id, amount)
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
                x -> Allocation(x["subgraphDeployment"]["id"], x["allocatedTokens"]),
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

function snapshot(;
    url::String,
    indexer_query::Union{Nothing,GQLQuery},
    subgraph_query::Union{Nothing,GQLQuery},
)
    client = Client(url)

    # Subgraphs
    if isnothing(subgraph_query)
        subgraph_query = GQLQuery(
            Dict("orderBy" => "signalledTokens", "orderDirection" => "desc"),
            ["id", "signalledTokens"],
        )
    end
    subgraphs_data = query(client, "subgraphDeployments"; query_args=subgraph_query.args, output_fields=subgraph_query.fields).data["subgraphDeployments"]
    subgraphs = map(x -> Subgraph(x["id"], x["signalledTokens"]), subgraphs_data)

    # Indexers
    if isnothing(indexer_query)
        indexer_query = GQLQuery(
            Dict("where" => Dict("stakedTokens_gte" => "100000000000000000000000")),
            [
                "id",
                "delegatedTokens",
                "stakedTokens",
                "allocations(where: {status:\"Active\"}){allocatedTokens,subgraphDeployment{id}}",
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
