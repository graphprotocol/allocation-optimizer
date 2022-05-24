module ActionQueue

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

struct AllocateActionInput <: ActionInput
    status::ActionStatus
    type::ActionType
    deploymentID::AbstractString
    amount::AbstractString
    source::AbstractString
    reason::AbstractString
end

struct UnallocateActionInput <: ActionInput
    status::ActionStatus
    type::ActionType
    allocationID::AbstractString
    source::AbstractString
    reason::AbstractString
end

struct ReallocateActionInput <: ActionInput
    status::ActionStatus
    type::ActionType
    allocationID::AbstractString
    amount::AbstractString
    source::AbstractString
    reason::AbstractString
end

structtodict(x::ActionInput) = Dict(string(k) => getfield(x, k) for k in propertynames(x))

function reallocate_actions(
    proposed_ipfs::Vector{T},
    existing_ipfs::Vector{T},
    proposed_allocations::Dict{T,<:Real},
    existing_allocations::Dict{T,T},
) where {T<:AbstractString}
    reallocate_ipfs = existing_ipfs ∩ proposed_ipfs
    actions = map(
        ipfs -> structtodict(
            ReallocateActionInput(
                queued,
                reallocate,
                existing_allocations[ipfs],
                string(proposed_allocations[ipfs]),
                "AllocationOpt",
                "AllocationOpt",
            ),
        ),
        reallocate_ipfs,
    )
    return actions, reallocate_ipfs
end

function allocate_actions(
    proposed_ipfs::Vector{T},
    reallocate_ipfs::Vector{T},
    proposed_allocations::Dict{T,<:Real},
) where {T<:AbstractString}
    open_ipfs = setdiff(proposed_ipfs, reallocate_ipfs)
    actions = map(
        ipfs -> structtodict(
            AllocateActionInput(
                queued,
                allocate,
                ipfs,
                string(proposed_allocations[ipfs]),
                "AllocationOpt",
                "AllocationOpt",
            ),
        ),
        open_ipfs,
    )
    return actions, open_ipfs
end

function unallocate_actions(
    existing_allocations::Dict{T,T},
    existing_ipfs::Vector{T},
    reallocate_ipfs::Vector{T},
    frozenlist::Vector{T},
) where {T<:AbstractString}
    close_ipfs = setdiff(setdiff(existing_ipfs, reallocate_ipfs), frozenlist)
    actions = map(
        ipfs -> structtodict(
            UnallocateActionInput(
                queued,
                unallocate,
                existing_allocations[ipfs],
                "AllocationOpt",
                "AllocationOpt",
            ),
        ),
        close_ipfs,
    )
    return actions, close_ipfs
end

end
