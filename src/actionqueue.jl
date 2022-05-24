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

end
