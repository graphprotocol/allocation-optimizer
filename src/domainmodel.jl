abstract type GraphEntity end
abstract type IPFSEntity <: GraphEntity end

struct GQLQuery
    args::Dict{AbstractString,Any}
    fields::AbstractVector{AbstractString}
end

struct Allocation <: IPFSEntity
    ipfshash::AbstractString
    amount::Real
    created_at_epoch::Integer

    function Allocation(
        ipfshash::AbstractString, amount::AbstractString, created_at_epoch::Integer
    )
        return new(ipfshash, togrt(amount), created_at_epoch)
    end
    function Allocation(ipfshash::AbstractString, amount::Real, created_at_epoch::Integer)
        return new(ipfshash, amount, created_at_epoch)
    end
end

struct Indexer <: GraphEntity
    id::AbstractString
    stake::Real
    allocations::AbstractVector{Allocation}

    function Indexer(id, delegation::AbstractString, stake::AbstractString, allocation)
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
    function Indexer(id, stake::Real, allocation)
        return new(id, stake, allocation)
    end
end

struct SubgraphDeployment <: IPFSEntity
    id::AbstractString
    ipfshash::AbstractString
    signal::Real

    function SubgraphDeployment(id, ipfshash, signal::AbstractString)
        return new(id, ipfshash, togrt(signal))
    end
    SubgraphDeployment(id, ipfshash, signal::Real) = new(id, ipfshash, signal)
end

struct Repository
    indexers::AbstractVector{Indexer}
    subgraphs::AbstractVector{SubgraphDeployment}
end

struct GraphNetworkParameters <: GraphEntity
    id::AbstractString
    principle_supply::Real
    issuance_rate_per_block::Real
    block_per_epoch::Integer
    total_tokens_signalled::Real
    current_epoch::Integer

    function GraphNetworkParameters(
        id,
        principle_supply::AbstractString,
        issuance_rate_per_block::AbstractString,
        block_per_epoch::Integer,
        total_tokens_signalled::AbstractString,
        current_epoch::Integer,
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
        principle_supply::Real,
        issuance_rate_per_block::Real,
        block_per_epoch::Integer,
        total_tokens_signalled::Real,
        current_epoch::Integer,
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
