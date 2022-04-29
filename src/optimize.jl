using Roots

export optimize

function optimize(optimize_id::String, repository::Repository, gas::Float64, network::Network, alloc_lifetime::Int64, preference_threshold::Float64, whitelist, blacklist)
    # Base case
    alloc, frepo = optimize(optimize_id, repository, whitelist, blacklist)

    # Create threshold based on suggested optimization without gas
    allocation_min_thresholds::Vector{Float64} = sort!(unique(values(alloc)))
    
    # Filter whitelist, reducing the number of subgraphs
    profit = 0.0
    for threshold in allocation_min_thresholds
        whitelist = filter(x -> alloc[x] > threshold, map(x -> x.id, frepo.subgraphs))
        if !isempty(whitelist)
            talloc, tfrepo = optimize(optimize_id, repository, whitelist, nothing)
            tprofit = sum(values(estimated_profit(tfrepo, talloc, gas, network, alloc_lifetime)))
            if tprofit >= profit
                if tprofit > profit
                end
                alloc = talloc
                frepo = tfrepo
                profit = tprofit
            end
        end
    end

    # Create vector of allocations that should be created this epoch
    alloc_list = filter(a -> a.amount != 0, map(alloc_id -> Allocation(alloc_id, alloc[alloc_id], network.current_epoch), collect(keys(alloc))))
    actions = create_actions(optimize_id, frepo, repository, network, alloc_list, alloc_lifetime, gas, preference_threshold, blacklist)

    # Excluding actions that are deemed to close, do final optimization
    whitelist =  map(x -> x.id, actions[2] ∪ actions[3])
   
    return optimize(optimize_id, repository, whitelist, nothing)
end

function optimize(optimize_id::String, repository::Repository, whitelist, blacklist)

    function solve_dual(Ω, ψ, σ)
        lower_bound = 1e-25
        upper_bound = (sum(.√(ψ .* Ω)))^2 / σ
        sol = find_zero(
            x -> sum(max.(0.0, .√(ψ .* Ω / x) .- Ω)) - σ,
            (lower_bound, upper_bound),
            Roots.Brent(),
        )
        return sol
    end

    function solve_primal(Ω, ψ, v)
        return max.(0.0, .√(ψ .* Ω / v) - Ω)
    end

    # Create a whitelist containing all indexers other than the one being optimised
    # And all whitelisted subgraphs. Then filter the repo using the whitelist.
    whitelist_with_indexer = create_whitelist(optimize_id, repository, whitelist, blacklist)
    filtered_repo = whitelist_repo(whitelist_with_indexer, repository)

    # Get values needed for optimisation
    i = indexer(optimize_id, repository)
    σ = i.stake + i.delegation
    ψ = signals(filtered_repo)
    Ω = subgraph_allocations(filtered_repo)

    # Solve the dual, and use that value to solve the primal
    v = solve_dual(Ω, ψ, σ)
    ω = solve_primal(Ω, ψ, v)

    # Output as a dict mapping subgraph ids to allocations
    sgraph_ids = map(x -> x.id, filtered_repo.subgraphs)
    alloc = Dict(sgraph_ids .=> ω)

    # Check the constraint as a test (+1 due to small rounding error
    @assert (sum(values(alloc)) >= σ - 1 && (sum(values(alloc)) <= σ + 1))

    return alloc, filtered_repo
end

function create_whitelist(id::String, repository::Repository, whitelist, blacklist)
    if !isnothing(whitelist) && !isnothing(blacklist)
        throw(ArgumentError("whitelist and blacklist cannot both be specified"))
    end

    # Whitelist all indexers other than the indexer to optimise
    other_indexers = blacklist_to_whitelist(String[id], repository.indexers)

    # Handle case where blacklist is specified but not whitelist
    if !isnothing(blacklist)
        whitelist = blacklist_to_whitelist(blacklist, repository.subgraphs)
    end

    # Handle case where neither blacklist nor whitelist is specified
    if isnothing(whitelist)
        whitelist = blacklist_to_whitelist(String[], repository.subgraphs)
    end

    # Combine indexer whitelist with subgraph whitelist
    whitelist_with_indexer = vcat(other_indexers, whitelist)

    return whitelist_with_indexer
end
