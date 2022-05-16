abstract type GraphEntity end
abstract type IPFSEntity <: GraphEntity end

struct GQLQuery
    args::Dict{String,Any}
    fields::Vector{String}
end

struct Allocation <: IPFSEntity
    ipfshash::String
    amount::Float64
    created_at_epoch::Int64

    function Allocation(ipfshash::String, amount::String, created_at_epoch::Int64)
        return new(ipfshash, togrt(amount), created_at_epoch)
    end
    function Allocation(ipfshash::String, amount::Float64, created_at_epoch::Int64)
        return new(ipfshash, amount, created_at_epoch)
    end
end

struct Indexer <: GraphEntity
    id::String
    stake::Float64
    allocations::Vector{Allocation}

    function Indexer(id, delegation::String, stake::String, allocation)
        return new(
            id,
            togrt(stake) + togrt(delegation),
            map(
                x -> Allocation(
                    x["subgraphDeployment"]["ipfsHash"],
                    x["allocatedTokens"],
                    x["createdAtEpoch"],
                ),
                allocation,
            ),
        )
    end
    function Indexer(id, stake::Float64, allocation)
        return new(id, stake, allocation)
    end
end

struct SubgraphDeployment <: IPFSEntity
    id::String
    ipfshash::String
    signal::Float64

    SubgraphDeployment(id, ipfshash, signal::String) = new(id, ipfshash, togrt(signal))
    SubgraphDeployment(id, ipfshash, signal::Float64) = new(id, ipfshash, signal)
end

struct Repository
    indexers::Vector{Indexer}
    subgraphs::Vector{SubgraphDeployment}
end

struct GraphNetworkParameters <: GraphEntity
    id::String
    principle_supply::Float64
    issuance_rate_per_block::Float64
    block_per_epoch::Int
    total_tokens_signalled::Float64
    current_epoch::Int

    function GraphNetworkParameters(
        id,
        principle_supply::String,
        issuance_rate_per_block::String,
        block_per_epoch::Int,
        total_tokens_signalled::String,
        current_epoch::Int,
    )
        return new(
            id,
            togrt(principle_supply),
            togrt(issuance_rate_per_block),
            block_per_epoch,
            togrt(total_tokens_signalled),
            current_epoch,
        )
    end
    function GraphNetworkParameters(
        id,
        principle_supply::Float64,
        issuance_rate_per_block::Float64,
        block_per_epoch::Int,
        total_tokens_signalled::Float64,
        current_epoch::Int,
    )
        return new(
            id,
            principle_supply,
            issuance_rate_per_block,
            block_per_epoch,
            total_tokens_signalled,
            current_epoch,
        )
    end
end

verify_ipfshash(x::AbstractString) = startswith(x, "Qm") && length(x) == 46

function togrt(x)::Float64
    return parse(Float64, x) / 1e18
end

signal(s::SubgraphDeployment) = s.signal

ipfshash(x::IPFSEntity) = x.ipfshash

id(x::GraphEntity) = x.id

allocation(i::Indexer) = i.allocations

allocated_stake(a::Allocation) = a.amount
