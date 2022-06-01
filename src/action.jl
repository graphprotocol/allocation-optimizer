function reallocate_ipfs(
    existing_ipfs::Vector{T}, proposed_ipfs::Vector{T}
) where {T<:AbstractString}
    return existing_ipfs ∩ proposed_ipfs
end
function open_ipfs(
    proposed_ipfs::Vector{T}, reallocate_ipfs::Vector{T}
) where {T<:AbstractString}
    return setdiff(proposed_ipfs, reallocate_ipfs)
end
function close_ipfs(
    existing_ipfs::Vector{T}, reallocate_ipfs::Vector{T}, frozenlist::Vector{T}
) where {T<:AbstractString}
    return setdiff(setdiff(existing_ipfs, reallocate_ipfs), frozenlist)
end
