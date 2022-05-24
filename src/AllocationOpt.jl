module AllocationOpt

using CSV
using GraphQLClient

export optimize_indexer, read_filterlists, push_allocations!

include("exceptions.jl")
include("domainmodel.jl")
include("query.jl")
include("service.jl")
include("ActionQueue.jl")

"""
    function optimize_indexer(id, whitelist, blacklist, pinnedlist, frozenlist, grtgas, minimum_allocation_amount, allocation_lifetime)

# Arguments
- `id::AbstractString`: The id of the indexer to optimise.
- `whitelist::Vector{AbstractString}`: Subgraph deployment IPFS hashes included in this list will be considered for, but not guaranteed allocation.
- `blacklist::Vector{AbstractString}`: Subgraph deployment IPFS hashes included in this list will not be considered, and will be suggested to close if there's an existing allocation.
- `pinnedlist::Vector{AbstractString}`: Subgraph deployment IPFS hashes included in this list will be guaranteed allocation. Currently unsupported.
- `frozenlist::Vector{AbstractString}`: Subgraph deployment IPFS hashes included in this list will not be considered during optimisation. Any allocations you have on these subgraphs deployments will remain.
- `grtgas::Real`: The maximum amount of GRT that you are willing to spend on each allocation transaction.
- `minimum_allocation_amount::Real`: The minimum amount of GRT that you are willing to allocate to a subgraph.
- `allocation_lifetime::Integer`: The number of epoches you assume to open each allocations for. Lifetime 1 means you are reallocating every epoch. 
    
# Examples
```julia-repl
julia> using AllocationOpt
julia> optimize_indexer("0x6ac85b9d834b51b14a7b0ed849bb5199e04c05c5", String["QmP4oSiQ7Wc4JTFk86m2JxGvR912NyBbxJnEdZawkYLTk4"], String[], String[], String[], 0.0, 0.0, 1)
1-element Vector{Tuple{String, Float64}}:
 ("QmP4oSiQ7Wc4JTFk86m2JxGvR912NyBbxJnEdZawkYLTk4", 5.539482411224138e6)
julia> optimize_indexer("foo", String["QmP4oSiQ7Wc4JTFk86m2JxGvR912NyBbxJnEdZawkYLTk4"], String[], String[], String[], 0.0, 0.0, 1)
ERROR: AllocationOpt.UnknownIndexerError()
julia> optimize_indexer("0x6ac85b9d834b51b14a7b0ed849bb5199e04c05c5", String["foo"], String[], String[], String[], 0.0, 0.0, 1)
ERROR: AllocationOpt.BadSubgraphIpfsHashError()
```
"""
function optimize_indexer(
    id::AbstractString,
    whitelist::AbstractVector{T},
    blacklist::AbstractVector{T},
    pinnedlist::AbstractVector{T},
    frozenlist::AbstractVector{T},
    grtgas::Real,
    minimum_allocation_amount::Real,
    allocation_lifetime::Integer,
) where {T<:AbstractString}
    userlists = vcat(whitelist, blacklist, pinnedlist, frozenlist)
    if !verify_ipfshashes(userlists)
        throw(BadSubgraphIpfsHashError())
    end

    @warn "grtgas is not currently optimised for."
    @warn "minimum_allocation_amount is not currently optimised for."
    @warn "allocation_lifetime is not currently optimised for."
    if !isempty(pinnedlist)
        @warn "pinnedlist is not currently optimised for."
    end

    # Construct whitelist and blacklist
    query_ipfshash_in = ipfshash_in(whitelist, pinnedlist)
    query_ipfshash_not_in = ipfshash_not_in(blacklist, frozenlist)

    # Get client
    client = gql_client()

    # Pull data from mainnet subgraph
    repo, network = snapshot(client, query_ipfshash_in, query_ipfshash_not_in)

    # Handle frozenlist
    # Get indexer
    indexer, repo = detach_indexer(repo, id)

    # Reduce indexer stake by frozenlist
    fstake = frozen_stake(client, id, frozenlist)
    indexer = Indexer(indexer.id, indexer.stake - fstake, indexer.allocations)

    # Optimise
    ω = optimize(indexer, repo)
    suggested_allocations = Dict(
        ipfshash(k) => v for (k, v) in zip(repo.subgraphs, ω) if v > 0.0
    )

    return suggested_allocations
end

"""
    function read_filterlists(filepath)
        
# Arguments

- `filepath::AbstractString`: A path to the CSV file that contains whitelist, blacklist, pinnedlist, frozenlist as columns.
"""
function read_filterlists(filepath::AbstractString)
    # Read file
    path = abspath(filepath)
    csv = CSV.File(path; header=1, types=String)

    # Filter out missings from csv
    listtypes = [:whitelist, :blacklist, :pinnedlist, :frozenlist]
    cols = map(x -> collect(skipmissing(csv[x])), listtypes)

    return cols
end

"""
    function push_allocations!(indexer_id, management_server_url, proposed_allocations, whitelist, blacklist, pinnedlist, frozenlist)

# Arguments

- `indexer_id::AbstractString`: Indexer id
- `management_server_url::T`: Indexer management server url, in format similar to http://localhost:18000
- `proposed_allocations::Dict{T,<:Real}`: The set of allocation to open returned by optimize_indexer
- `whitelist::AbstractVector{T}`: Unused. Here for completeness.
- `blacklist::AbstractVector{T}`: Unused. Here for completeness.
- `pinnedlist::AbstractVector{T}`: Unused. Here for completeness.
- `frozenlist::AbstractVector{T}`: Make sure to not close these allocations as they are frozen.
"""
function push_allocations!(
    indexer_id::AbstractString,
    management_server_url::T,
    proposed_allocations::Dict{T,<:Real},
    whitelist::AbstractVector{T},
    blacklist::AbstractVector{T},
    pinnedlist::AbstractVector{T},
    frozenlist::AbstractVector{T},
) where {T<:AbstractString}
    actions = []

    # Query existing allocations that are not frozen
    existing_allocations = query_indexer_allocations(gql_client(), indexer_id)
    existing_allocs = Dict(ipfshash.(existing_allocations) .=> id.(existing_allocations))
    existing_ipfs = ipfshash.(existing_allocations)
    proposed_ipfs = collect(keys(proposed_allocations))

    # Generate ActionQueue inputs
    reallocations, reallocate_ipfs = ActionQueue.reallocate_actions(
        proposed_ipfs, existing_ipfs, proposed_allocations, existing_allocs
    )
    open_allocations, open_ipfs = ActionQueue.allocate_actions(
        proposed_ipfs, reallocate_ipfs, proposed_allocations
    )
    close_allocations, close_ipfs = ActionQueue.unallocate_actions(
        existing_allocs, existing_ipfs, reallocate_ipfs, frozenlist
    )
    actions = vcat(reallocations, open_allocations, close_allocations)

    # Send ActionQueue inputs to indexer management server
    client = Client(management_server_url)
    response = mutate(client, "queueActions", Dict("actions" => actions))

    return response
end

end
