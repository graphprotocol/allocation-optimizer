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

struct AllocateActionInput <: ActionInput begin
    status::ActionStatus
    type::ActionType
    deploymentID::AbstractString
    amount::AbstractString
end

struct UnallocateActionInput <: ActionInput begin
    status::ActionStatus
    type::ActionType
    allocationID::AbstractString
end

struct ReallocateActionInput <: ActionInput begin
    status::ActionStatus
    type::ActionType
    allocationID::AbstractString
    amount::AbstractString
end

structtodict(x::<:ActionInput) = Dict(string(k) => getfield(x, k) for k in propertynames(x))