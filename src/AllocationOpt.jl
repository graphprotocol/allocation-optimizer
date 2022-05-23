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
    suggested_allocations = map((x, y) -> (x.ipfshash, y), repo.subgraphs, ω)

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

function push_allocations!(
    management_server_url::AbstractString,
    allocations::AbstractVector{Tuple{AbstractString,Real}},
    whitelist::AbstractVector{T},
    blacklist::AbstractVector{T},
    pinnedlist::AbstractVector{T},
    frozenlist::AbstractVector{T},
) where {T<:AbstractString}
    # Get the indexer being optimised
    # Connect to database
    client = Client(management_server_url)

    # For each allocation
    # If allocation on subgraph exists
    # If new allocation on subgraph to open - reallocate
    # query_args = structtodict(ReallocateActionInput(queued, reallocate, alloc_id))
    # Else close
    # query_args = structtodict(UnallocateActionInput(queued, unallocate, alloc_id, string(alloc)))
    # Open all remaining allocations
    actions = []
    for alloc in allocations
        action = structtodict(
            ActionQueue.AllocateActionInput(
                ActionQueue.queued, ActionQueue.allocate, string.(alloc)...
            ),
        )
        push!(actions, action)
    end
    # send to database
    return mutate(client, "queueActions", Dict("actions" => actions))
end

end
