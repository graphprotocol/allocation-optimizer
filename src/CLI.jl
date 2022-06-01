module CLI
using Formatting
include("action.jl")

function reallocate_actions(
    proposed_ipfs::Vector{T},
    existing_ipfs::Vector{T},
    proposed_allocations::Dict{T,<:Real},
    existing_allocations::Dict{T,T},
) where {T<:AbstractString}
    ipfses = reallocate_ipfs(existing_ipfs, proposed_ipfs)
    actions = map(
        ipfs ->
            "\e[0mgraph indexer rules stop $(ipfs)\n\e[1m\e[38;2;255;0;0;249mCheck before submitting: \e[0mgraph indexer rules set $(ipfs) decisionBasis always allocationAmount $(format(proposed_allocations[ipfs]))",
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
        ipfs ->
            "\e[0mgraph indexer rules set $(ipfs) decisionBasis always allocationAmount $(format(proposed_allocations[ipfs]))",
        ipfses,
    )
    return actions, ipfses
end

function unallocate_actions(
    existing_ipfs::Vector{T}, reallocate_ipfs::Vector{T}, frozenlist::Vector{T}
) where {T<:AbstractString}
    ipfses = setdiff(setdiff(existing_ipfs, reallocate_ipfs), frozenlist)
    actions = map(ipfs -> "\e[0mgraph indexer rules stop $(ipfs)", ipfses)
    return actions, ipfses
end
end
