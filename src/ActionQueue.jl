module ActionQueue
include("action.jl")

@enum ActionStatus begin
    queued
    approved
    pending
    success
    failed
    canceled
end

@enum ActionType begin
    allocate
    unallocate
    reallocate
    collect
end

abstract type ActionInput end

# TODO: Priority from the optimizer are all hardcoded to 0, in future allow config
# Since priority is not actively used in actions queue
struct AllocateActionInput <: ActionInput
    status::ActionStatus
    type::ActionType
    deploymentID::AbstractString
    amount::AbstractString
    source::AbstractString
    reason::AbstractString
    priority::Int64
end

struct UnallocateActionInput <: ActionInput
    status::ActionStatus
    type::ActionType
    allocationID::AbstractString
    deploymentID::AbstractString
    source::AbstractString
    reason::AbstractString
    priority::Int64
end

struct ReallocateActionInput <: ActionInput
    status::ActionStatus
    type::ActionType
    allocationID::AbstractString
    deploymentID::AbstractString
    amount::AbstractString
    source::AbstractString
    reason::AbstractString
    priority::Int64
end

structtodict(x::ActionInput) = Dict(string(k) => getfield(x, k) for k in propertynames(x))

function reallocate_actions(
    proposed_ipfs::Vector{T},
    existing_ipfs::Vector{T},
    proposed_allocations::Dict{T,<:Real},
    existing_allocations::Dict{T,T},
) where {T<:AbstractString}
    ipfses = reallocate_ipfs(existing_ipfs, proposed_ipfs)
    actions = map(
        ipfs -> structtodict(
            ReallocateActionInput(
                queued,
                reallocate,
                existing_allocations[ipfs],
                ipfs,
                string(proposed_allocations[ipfs]),
                "AllocationOpt",
                "AllocationOpt",
                0,
            ),
        ),
        ipfses,
    )
    return actions, ipfses
end

function allocate_actions(
    proposed_ipfs::Vector{T},
    reallocate_ipfs::Vector{T},
    proposed_allocations::Dict{T,<:Real},
) where {T<:AbstractString}
    ipfses = open_ipfs(proposed_ipfs, reallocate_ipfs)
    actions = map(
        ipfs -> structtodict(
            AllocateActionInput(
                queued,
                allocate,
                ipfs,
                string(proposed_allocations[ipfs]),
                "AllocationOpt",
                "AllocationOpt",
                0,
            ),
        ),
        ipfses,
    )
    return actions, ipfses
end

function unallocate_actions(
    existing_allocations::Dict{T,T},
    existing_ipfs::Vector{T},
    reallocate_ipfs::Vector{T},
    frozenlist::Vector{T},
) where {T<:AbstractString}
    ipfses = close_ipfs(existing_ipfs, reallocate_ipfs, frozenlist)
    actions = map(
        ipfs -> structtodict(
            UnallocateActionInput(
                queued,
                unallocate,
                existing_allocations[ipfs],
                ipfs,
                "AllocationOpt",
                "AllocationOpt",
                0,
            ),
        ),
        ipfses,
    )
    return actions, ipfses
end

end
