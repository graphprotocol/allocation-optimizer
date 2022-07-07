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
    function Indexer(allocation)
        return new(
            "",
            0.0,
            map(x -> Allocation(x["id"], x["subgraphDeployment"]["ipfsHash"]), allocation),
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
