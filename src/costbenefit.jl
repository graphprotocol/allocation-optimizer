export estimated_profit, indexer_subgraph_rewards, subgraph_rewards, issued_token, compare_rewards, create_actions

function allocation_indicator(alloc_amount::Float64)
    alloc_amount > 0.0 ? 1.0 : 0.0
end

function allocation_indicator(alloc_amounts::Vector{Float64})
    map(amt -> allocation_indicator(amt), alloc_amounts)
end

function calculate_gas_fee(alloc_amount::Float64, gas)
    allocation_indicator(alloc_amount) * gas
end

function calculate_gas_fee(allocs::Dict{String, Float64}, gas)
    map(x -> calculate_gas_fee(x, gas), values(allocs))
end

function calculate_gas_fee(allocs::Vector{Allocation}, gas)
    map(a -> calculate_gas_fee(a.amount, gas), allocs)
end

function indicator_gas_fee(alloc::Allocation, gas)
    claim_proportion_of_openclose = 0.3
    claim_gas = claim_proportion_of_openclose * gas

    # open + close + claim
    calculate_gas_fee(alloc.amount, gas) + calculate_gas_fee(alloc.amount, gas) + calculate_gas_fee(alloc.amount, claim_gas)
end

function indicator_gas_fee(allocs::Dict{String, Float64}, gas)
    claim_proportion_of_openclose = 0.3
    claim_gas = claim_proportion_of_openclose * gas

    # open + close + claim
    calculate_gas_fee(allocs, gas) + calculate_gas_fee(allocs, gas) + calculate_gas_fee(allocs, claim_gas)
end

function indicator_gas_fee(allocs::Vector{Allocation}, gas)
    claim_proportion_of_openclose = 0.3
    claim_gas = claim_proportion_of_openclose * gas

    # open + close + claim
    calculate_gas_fee(allocs, gas) + calculate_gas_fee(allocs, gas) + calculate_gas_fee(allocs, claim_gas)
end

function estimated_profit(repo::Repository, allocs::Vector{Allocation}, gas::Float64, network::Network, alloc_lifetime::Int)
    return indexer_subgraph_rewards(repo, network, allocs, alloc_lifetime) - indicator_gas_fee(allocs, gas)
end

function estimated_profit(repo::Repository, allocs::Dict{String, Float64}, gas::Float64, network::Network, alloc_lifetime::Int)
    return indexer_subgraph_rewards(repo, network, allocs, alloc_lifetime) - indicator_gas_fee(allocs, gas)
end

# daily issuance
function issued_token(network::Network)
    network.principle_supply * network.issuance_rate_per_block ^ network.block_per_epoch - network.principle_supply
end

function issued_token(network::Network, alloc_lifetime::Int)
    network.principle_supply * network.issuance_rate_per_block ^ (network.block_per_epoch * max(0, alloc_lifetime)) - network.principle_supply
end

function subgraph_rewards(repo::Repository, network::Network, alloc_lifetime::Int)
    signal_shares(repo, network) * issued_token(network, alloc_lifetime)
end

function subgraph_rewards(repo::Repository, network::Network, alloc_lifetime::Int, alloc_list::Dict{String, Float64})
    signal_shares(repo, network, alloc_list) * issued_token(network, alloc_lifetime)
end

function subgraph_rewards(repo::Repository, network::Network, alloc_lifetime::Int, alloc_list::Vector{Allocation})
    signal_shares(repo, network, alloc_list) * issued_token(network, alloc_lifetime)
end

function indexer_subgraph_rewards(repo::Repository, network::Network, alloc_id::String, alloc_amount::Float64, alloc_lifetime::Int)
    Ω = alloc_amount + allocation_amounts(repo, alloc_id)
    alloc_reward = ((subgraph_rewards(repo, network, alloc_lifetime, Dict(alloc_id => alloc_amount)) * alloc_amount) / Ω)[1]
    return isnan(alloc_reward) ? 0.0 : alloc_reward
end

function indexer_subgraph_rewards(repo::Repository, network::Network, alloc_list::Dict{String, Float64}, alloc_lifetime::Int)
    ω_i = collect(values(alloc_list))
    Ω = ω_i + subgraph_allocations(repo, collect(keys(alloc_list)))  # Does not include optimised indexer
    ans = replace!(((subgraph_rewards(repo, network, alloc_lifetime, alloc_list) .* ω_i) ./ Ω), NaN=>0.0)
    return ans
end

function indexer_subgraph_rewards(repo::Repository, network::Network, alloc_list::Vector{Allocation}, alloc_lifetime::Int)
    ω_i = map(a -> a.amount, alloc_list)
    Ω = ω_i + subgraph_allocations(repo,  map(a -> a.id, alloc_list))  # Does not include optimised indexer
    ans = replace!(((subgraph_rewards(repo, network, alloc_lifetime, alloc_list) .* ω_i) ./ Ω), NaN=>0.0)
    return ans
end

function does_exist(alloc_id::String, existing_allocations_in_plan)
    findfirst(y -> y.id == alloc_id, existing_allocations_in_plan)
end

function compare_rewards(indexer_id::String, filtered_repo::Repository, current_repo::Repository, network::Network, alloc_list::Vector{Allocation}, alloc_lifetime::Int, gas::Float64, preference_threshold::Float64)
    new_allocation_ids = map(a -> a.id, filter(a -> (a.id in map(a -> a.id, allocations_by_indexer(indexer_id, current_repo))), alloc_list))

    reward_without_reallocate = map(a -> (
        !(a.id in new_allocation_ids) ? 0.0 : 
            (preference_threshold * indexer_subgraph_rewards(
                current_repo, 
                network, 
                a.id, 
                allocation_amounts(indexer_id, current_repo, a.id).amount, 
                (a.created_at_epoch + alloc_lifetime - network.current_epoch)
            ))
    ), alloc_list)

    plan_estimated_profit = estimated_profit(filtered_repo, alloc_list, gas, network, alloc_lifetime)

    return plan_estimated_profit - reward_without_reallocate
end

function create_actions(indexer_id::String, filtered_repo::Repository, current_repo::Repository, network::Network, alloc_list::Vector{Allocation}, alloc_lifetime::Int, gas::Float64, preference_threshold::Float64)
    # Identify allocations that need to be closed, reallocated, opened
    alloc_current = allocations_by_indexer(indexer_id, current_repo)
    alloc_id_in_plan = map(a->a.id, alloc_list)
    alloc_id_current = map(a->a.id, alloc_current)

    # Close the ones in indexer's current repo but not in alloc_list at all
    close_actions::Vector{Allocation} = filter(a -> !(a.id in alloc_id_in_plan), alloc_current)
    # Open the ones in indexer's alloc_list not in current repo at all
    open_actions::Vector{Allocation} = filter(a -> !(a.id in alloc_id_current), alloc_list)

    comparison = compare_rewards(indexer_id, filtered_repo, current_repo, network, alloc_list, alloc_lifetime, gas, preference_threshold)
    indicators = allocation_indicator(comparison)

    realloc_actions = map(i -> alloc_list[i], findall(isone, indicators))
    close_actions = append!(map(i -> alloc_list[i], findall(iszero, indicators)), close_actions)
    
    return (close_actions, open_actions, realloc_actions)
end
