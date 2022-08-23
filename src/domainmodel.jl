abstract type GraphEntity end
abstract type IPFSEntity <: GraphEntity end

struct GQLQuery
    args::Dict{AbstractString,Any}
    fields::AbstractVector{AbstractString}
end

struct Allocation <: IPFSEntity
    id::AbstractString
    ipfshash::AbstractString
    amount::Real
    created_at_epoch::Integer

    function Allocation(
        id::AbstractString, ipfshash::AbstractString, amount::AbstractString
    )
        return new(id, ipfshash, togrt(amount), 0)
    end
    function Allocation(
        ipfshash::AbstractString, amount::AbstractString, created_at_epoch::Integer
    )
        return new("", ipfshash, togrt(amount), created_at_epoch)
    end
    function Allocation(ipfshash::AbstractString, amount::Real, created_at_epoch::Integer)
        return new("", ipfshash, amount, created_at_epoch)
    end
    function Allocation(id::AbstractString, ipfshash::AbstractString)
        return new(id, ipfshash, 0.0, 0)
    end
end

struct Indexer <: GraphEntity
    id::AbstractString
    stake::Real
    allocations::AbstractVector{Allocation}

    function Indexer(
        id,
        delegation::AbstractString,
        stake::AbstractString,
        locked_tokens::AbstractString,
        allocation,
    )
        return new(
            id,
            togrt(stake) + togrt(delegation) - togrt(locked_tokens),
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
    function Indexer(allocation)
        return new(
            "",
            0.0,
            map(
                x -> Allocation(
                    x["id"], x["subgraphDeployment"]["ipfsHash"], x["allocatedTokens"]
                ),
                allocation,
            ),
        )
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

# TODO: Abstractify
struct GraphNetworkParameters
    id::AbstractString
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

stake(i::Indexer) = i.stake

function other_stake(repo::Repository, indexer::Indexer)
    return sum(stake.(repo.indexers)) - stake(indexer)
end

function allocated_stake_onto_ipfs(ipfshashes::Vector{String}, allocs::Vector{Allocation})
    # Dictionary might be cleaner but this shall work for now (strict ordering
    stakes = zeros(length(ipfshashes))
    existing_allocs_hashes = ipfshash.(allocs)
    rearrange_allocs = Allocation[]
    for hash in ipfshashes
        if hash in existing_allocs_hashes
            push!(rearrange_allocs, allocs[findfirst(a -> ipfshash(a) == hash, allocs)])
        end
    end
    existing_ixs = findall(i -> i in existing_allocs_hashes, ipfshashes)
    stakes[existing_ixs] .= allocated_stake.(rearrange_allocs)
    return stakes
end
