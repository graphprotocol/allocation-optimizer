module AllocationOpt

using CSV
using GraphQLClient

export network_state, optimize_indexer, read_filterlists
export push_allocations!, create_rules!, apply_preferences

include("exceptions.jl")
include("domainmodel.jl")
include("query.jl")
include("service.jl")
include("ActionQueue.jl")
include("CLI.jl")

"""
    function network_state(id, whitelist, blacklist, pinnedlist, frozenlist, indexer_service_network_url)
    
# Arguments
- `id::AbstractString`: The id of the indexer to optimise.
- `network_id`: The id of the network the indexer want to optimise on.
- `whitelist::Vector{AbstractString}`: Subgraph deployment IPFS hashes included in this list will be considered for, but not guaranteed allocation.
- `blacklist::Vector{AbstractString}`: Subgraph deployment IPFS hashes included in this list will not be considered, and will be suggested to close if there's an existing allocation.
- `pinnedlist::Vector{AbstractString}`: Subgraph deployment IPFS hashes included in this list will be guaranteed allocation. Currently unsupported.
- `frozenlist::Vector{AbstractString}`: Subgraph deployment IPFS hashes included in this list will not be considered during optimisation. Any allocations you have on these subgraphs deployments will remain.
- `indexer_service_network_url::AbstractString`: The URL that exposes the indexer service's network endpoint. Must begin with http. Example: http://localhost:7600/network.
"""
function network_state(
    indexer_id::AbstractString,
    network_id::Int,
    whitelist::AbstractVector{T},
    blacklist::AbstractVector{T},
    pinnedlist::AbstractVector{T},
    frozenlist::AbstractVector{T},
    indexer_service_network_url::AbstractString,
) where {T<:AbstractString}
    userlists = vcat(whitelist, blacklist, pinnedlist, frozenlist)
    if !verify_ipfshashes(userlists)
        throw(BadSubgraphIpfsHashError())
    end

    # Construct whitelist and blacklist
    query_ipfshash_in = ipfshash_in(whitelist, pinnedlist)
    query_ipfshash_not_in = ipfshash_not_in(blacklist, frozenlist)

    # Get client
    client = Client(indexer_service_network_url)

    # Pull data from mainnet subgraph
    repo = snapshot(client, query_ipfshash_in, query_ipfshash_not_in)
    network = networkparameters(client, network_id)
    # Handle frozenlist
    # Get indexer
    indexer, repo = detach_indexer(repo, indexer_id)

    # Reduce indexer stake by frozenlist
    fstake = frozen_stake(client, indexer_id, frozenlist)
    # Also reduce indexer stake by number of pinned subgraph times 0.1 grt
    pinned_amount = 0.1
    pstake = pinned_amount * length(pinnedlist)
    indexer = Indexer(indexer.id, indexer.stake - fstake - pstake, indexer.allocations)

    return repo, indexer, network
end

"""
function apply_preferences(network::GraphNetworkParameters, gas::Real, allocation_lifetime::Int, ω::Matrix{T}, ψ::AbstractVector{T}, Ω::AbstractVector{T}) where {T <: Real}

# Arguments
- `network::GraphNetworkParameters`: Contains the current network parameters.
- `gas::Float64`: The gas in grt that the indexer will spend on the allocation transaction. We use this to
    calculate profit, but note that the assumption that this will be the price at the end of the allocation
    lifetime is probably bad. Gas is constantly changing.
- `allocation_lifetime::Integer`: The number of epochs for which these allocations would be open. An allocation earns indexing rewards upto 28 epochs.
- `ω::Matrix{Real}`: A matrix of allocations in which the rows have different sparsities.
- `ψ::Vector{Real}`: A vector of subgraph signals.
- `Ω::Vector{Real}`: A vector of the allocations of other indexers.
"""
function apply_preferences(
    network::GraphNetworkParameters,
    gas::Real,
    allocation_lifetime::Int,
    ω::AbstractMatrix{T},
    ψ::AbstractVector{T},
    Ω::AbstractVector{T},
) where {T<:Real}
    profits = map(x -> profit(network, gas, allocation_lifetime, x, ψ, Ω), eachcol(ω))
    if all(profits .≤ 0)
        throw(
            ArgumentError(
                "Solver was unable to find a solution with positive expected profit."
            ),
        )
    end
    i = argmax(profits)
    return ω[:, i]
end

"""
function apply_preferences(network::GraphNetworkParameters, gas::Real, allocation_lifetime::Int, verbose::Bool, ω::Matrix{T}, ψ::AbstractVector{T}, Ω::AbstractVector{T}) where {T <: Real}

# Arguments
- `network::GraphNetworkParameters`: Contains the current network parameters.
- `gas::Float64`: The gas in grt that the indexer will spend on the allocation transaction. We use this to
    calculate profit, but note that the assumption that this will be the price at the end of the allocation
    lifetime is probably bad. Gas is constantly changing.
- `allocation_lifetime::Integer`: The number of epochs for which these allocations would be open. An allocation earns indexing rewards upto 28 epochs.
- `verbose::Bool`: A boolean flag for the verbosity of applying preferences
- `ω::Matrix{Real}`: A matrix of allocations in which the rows have different sparsities.
- `ψ::Vector{Real}`: A vector of subgraph signals.
- `Ω::Vector{Real}`: A vector of the allocations of other indexers.
"""
function apply_preferences(
    network::GraphNetworkParameters,
    gas::Real,
    allocation_lifetime::Int,
    ω::AbstractMatrix{T},
    ψ::AbstractVector{T},
    Ω::AbstractVector{T},
    ipfshashes::Vector{String},
) where {T<:Real}
    profit_sums = map(x -> profit(network, gas, allocation_lifetime, x, ψ, Ω), eachcol(ω))
    principle_stake = sum(ω[:, 1])

    if all(profit_sums .≤ 0)
        throw(
            ArgumentError(
                "Solver was unable to find a solution with positive expected profit."
            ),
        )
    end

    top_three = partialsortperm(profit_sums, 1:min(3, size(ω, 2)); rev=true)

    # APR and profit details for at most 3 top plans of allocations
    summary = map(
        (profit, x) -> (
            profit,
            annual_percentage_return(profit, principle_stake, allocation_lifetime),
            apr(network, gas, allocation_lifetime, x, ψ, Ω, ipfshashes),
        ),
        profit_sums[top_three],
        eachcol(ω[:, top_three]),
    )
    println("top plans:")
    println.(summary)
    i = argmax(profit_sums)
    return ω[:, i]
end

"""
    function optimize_indexer(indexer, repo, maximum_new_allocations, pinnedlist)

# Arguments
- `indexer::Indexer`: The indexer being optimised.
- `repo::Repository`: Contains the current network state.
- `maximum_new_allocations::Int`: The maximum number of new allocations you would like the optimizer to open.
- `τ::AbstractFloat`: Interval [0,1]. As τ gets closer to 0, the optimiser selects greedy allocations that maximise your short-term, expected rewards, but network dynamics will affect you more. The opposite occurs as τ approaches 1.
- `filter_function::Function`: A function that filters the optimal results as per indexer preferences.
- `pinnedlist::Vector{AbstractString}`: Subgraph deployment IPFS hashes included in this list will be guaranteed allocation at 0.1 GRT.
```
"""
function optimize_indexer(
    indexer::Indexer,
    repo::Repository,
    fullrepo::Repository,
    maximum_new_allocations::Integer,
    τ::AbstractFloat,
    filter_function::Function,
    pinnedlist::AbstractVector{T},
) where {T<:AbstractString}
    if τ > 1 || τ < 0
        throw(ArgumentError("τ must be between 0 and 1."))
    end
    if maximum_new_allocations > length(repo.subgraphs)
        @warn "Maximum new allocations is more than the number of available subgraph deployments; setting it to the number of subgraphs: $(length(repo.subgraphs))"
        maximum_new_allocations = length(repo.subgraphs)
    end

    # Optimise    # ω = optimize(indexer, repo, maximum_new_allocations)
    Ω = discountΩ(fullrepo, repo, τ)
    ψ = signal.(repo.subgraphs)
    σ = indexer.stake
    ω = optimize(Ω, ψ, σ, maximum_new_allocations, filter_function)
    pinnedixs = findall(x -> x in pinnedlist, ipfshash.(repo.subgraphs))
    pinned_amount = 0.1
    ω[pinnedixs] .+= pinned_amount

    # Filter results with deployment IPFS hashes
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
    indexer_service_network_url::T,
    proposed_allocations::Dict{T,<:Real},
    whitelist::AbstractVector{T},
    blacklist::AbstractVector{T},
    pinnedlist::AbstractVector{T},
    frozenlist::AbstractVector{T},
) where {T<:AbstractString}
    actions = []

    # Query existing allocations that are not frozen
    existing_allocations = query_indexer_allocations(
        Client(indexer_service_network_url), indexer_id
    )
    existing_allocs::Dict{String,String} = Dict(
        ipfshash.(existing_allocations) .=> id.(existing_allocations)
    )
    existing_ipfs::Vector{String} = ipfshash.(existing_allocations)
    proposed_ipfs::Vector{String} = collect(keys(proposed_allocations))

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

function create_rules!(
    indexer_id::AbstractString,
    indexer_service_network_url::T,
    proposed_allocations::Dict{T,<:Real},
    whitelist::AbstractVector{T},
    blacklist::AbstractVector{T},
    pinnedlist::AbstractVector{T},
    frozenlist::AbstractVector{T},
) where {T<:AbstractString}
    actions = []

    # Query existing allocations that are not frozen
    existing_allocations = query_indexer_allocations(
        Client(indexer_service_network_url), indexer_id
    )
    existing_allocs::Dict{String,String} = Dict(
        ipfshash.(existing_allocations) .=> id.(existing_allocations)
    )
    existing_ipfs::Vector{String} = ipfshash.(existing_allocations)
    proposed_ipfs::Vector{String} = collect(keys(proposed_allocations))

    # Generate CLI commands
    reallocations, reallocate_ipfs = CLI.reallocate_actions(
        proposed_ipfs, existing_ipfs, proposed_allocations, existing_allocs
    )
    existing_ipfs ∩ proposed_ipfs
    open_allocations, open_ipfs = CLI.allocate_actions(
        proposed_ipfs, reallocate_ipfs, proposed_allocations
    )
    close_allocations, close_ipfs = CLI.unallocate_actions(
        existing_ipfs, reallocate_ipfs, frozenlist
    )
    actions = vcat(close_allocations, reallocations, open_allocations)
    return actions
end

end
