export estimated_profit, indexer_subgraph_rewards, rewards, subgraph_rewards

function calculate_gas_fee(allocs::Dict{String, Float64}, gas)
    sum(map(x -> x > 0 ? gas : 0, values(allocs)))
end

function sum_gas_fee(allocs::Dict{String, Float64}, gas)
    claim_proportion_of_openclose = 0.3
    claim_gas = claim_proportion_of_openclose * gas

    # open + close + claim
    calculate_gas_fee(allocs, gas) + calculate_gas_fee(allocs, gas) + calculate_gas_fee(allocs, claim_gas)
end

function estimated_profit(repo::Repository, allocs::Dict{String, Float64}, gas)
    profit = rewards(repo, allocs) - sum_gas_fee(allocs, gas)
    return profit
end

function estimated_profit(repo::Repository, allocs::Dict{String, Float64}, gas::Float64, network::Network, alloc_lifetime::Int)
    profit = sum(indexer_subgraph_rewards(repo, network, allocs, alloc_lifetime::Int)) - sum_gas_fee(allocs, gas)
    return profit
end

function issued_token(network::Network, alloc_lifetime::Int)
    network.principle_supply * network.issuance_rate_per_block ^ (network.block_per_epoch * alloc_lifetime) - network.principle_supply
end

function subgraph_rewards(repo::Repository, network::Network, alloc_lifetime::Int)
    signal_shares(repo, network) * issued_token(network, alloc_lifetime)
end

function indexer_subgraph_rewards(repo::Repository, network::Network, alloc_list::Dict{String, Float64}, alloc_lifetime::Int)
    ω_i = collect(values(alloc_list))
    Ω = ω_i + subgraph_allocations(repo)  # Does not include optimised indexer
    ans = replace!((subgraph_rewards(repo, network, alloc_lifetime) .* ω_i ./ Ω), NaN=>0.0)
    return ans
end

function rewards(repo::Repository, allocs::Dict{String, Float64})
    total = 0
    ω_i = collect(values(allocs))
    Ω = ω_i + subgraph_allocations(repo)  # Does not include optimised indexer
    total = sum(signals(repo) .* ω_i ./ Ω)
    return total
end
