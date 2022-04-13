export estimated_profit, indexer_subgraph_rewards, subgraph_rewards, issued_token

function calculate_gas_fee(alloc_amount::Float64, gas)
    alloc_amount > 0.0 ? gas : 0.0
end

function calculate_gas_fee(allocs::Dict{String, Float64}, gas)
    map(x -> calculate_gas_fee(x, gas), values(allocs))
end

function indicator_gas_fee(alloc::Float64, gas)
    claim_proportion_of_openclose = 0.3
    claim_gas = claim_proportion_of_openclose * gas

    # open + close + claim
    calculate_gas_fee(alloc, gas) + calculate_gas_fee(alloc, gas) + calculate_gas_fee(alloc, claim_gas)
end

function indicator_gas_fee(allocs::Dict{String, Float64}, gas)
    claim_proportion_of_openclose = 0.3
    claim_gas = claim_proportion_of_openclose * gas

    # open + close + claim
    calculate_gas_fee(allocs, gas) + calculate_gas_fee(allocs, gas) + calculate_gas_fee(allocs, claim_gas)
end

function simple_profit(repo::Repository, allocs::Dict{String, Float64}, gas::Float64, network::Network, alloc_lifetime::Int)
    sum(indexer_subgraph_rewards(repo, network, allocs, alloc_lifetime)) - sum(indicator_gas_fee(allocs, gas))
end

function estimated_profit(repo::Repository, allocs::Dict{String, Float64}, gas::Float64, network::Network, alloc_lifetime::Int)
    return indexer_subgraph_rewards(repo, network, allocs, alloc_lifetime) - indicator_gas_fee(allocs, gas)
end

function issued_token(network::Network, alloc_lifetime::Int)
    network.principle_supply * network.issuance_rate_per_block ^ (network.block_per_epoch * alloc_lifetime) - network.principle_supply
end

# daily issuance
function issued_token(network::Network)
    network.principle_supply * network.issuance_rate_per_block ^ network.block_per_epoch - network.principle_supply
end

function subgraph_rewards(repo::Repository, network::Network, alloc_lifetime::Int)
    signal_shares(repo, network) * issued_token(network, alloc_lifetime)
end

function subgraph_rewards(repo::Repository, network::Network, alloc_lifetime::Int, alloc_list::Dict{String, Float64})
    signal_shares(repo, network, alloc_list) * issued_token(network, alloc_lifetime)
end

function indexer_subgraph_rewards(repo::Repository, network::Network, alloc_id::String, alloc_amount::Float64, alloc_lifetime::Int)
    Ω = alloc_amount + allocations(repo, alloc_id)
    alloc_reward = (subgraph_rewards(repo, network, alloc_lifetime, Dict(alloc_id => alloc_amount)) * alloc_amount / Ω)[1]
    return isnan(alloc_reward) ? 0.0 : alloc_reward
end

function indexer_subgraph_rewards(repo::Repository, network::Network, alloc_list::Dict{String, Float64}, alloc_lifetime::Int)
    ω_i = collect(values(alloc_list))
    Ω = ω_i + subgraph_allocations(repo)  # Does not include optimised indexer
    ans = replace!((subgraph_rewards(repo, network, alloc_lifetime, alloc_list) .* ω_i ./ Ω), NaN=>0.0)
    return ans
end

function does_exist(alloc_id::String, existing_allocations_in_plan)
    findfirst(y -> y.id == alloc_id, existing_allocations_in_plan)
end

function compare_rewards(indexer_id::String, filtered_repo::Repository, current_repo::Repository, network::Network, alloc_list::Dict{String, Float64}, alloc_lifetime::Int, gas::Float64)
    plan_estimated_profit = estimated_profit(filtered_repo, alloc_list, gas, network, alloc_lifetime)
    preference_threshold = 1.05

    # find allocations in alloc (our plan) that points to an existing allocation in our current repo 
    existing_allocations_in_plan = filter(allocation -> allocation.id in keys(alloc_list) , allocations_by_indexer(indexer_id, current_repo))
    
    predicted_rewards_for_existing_allocations = map(alloc_id
     -> (
            isnothing(does_exist(alloc_id, existing_allocations_in_plan)) ? 0.0 :
            (
                (preference_threshold * indexer_subgraph_rewards(
                    filtered_repo, 
                    network, 
                    alloc_id, 
                    existing_allocations_in_plan[does_exist(alloc_id, existing_allocations_in_plan)].amount, 
                    alloc_lifetime
                )) 
            )
        ),
        collect(keys(alloc_list))
    )
    # TODO: extra conditioning for the ones that might expire 

    return min(predicted_rewards_for_existing_allocations, plan_estimated_profit - predicted_rewards_for_existing_allocations)
end
