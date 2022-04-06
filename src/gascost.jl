export estimated_profit

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

function rewards(repo::Repository, allocs::Dict{String, Float64})
    total = 0
    ω_i = collect(values(allocs))
    Ω = ω_i + subgraph_allocations(repo)  # Does not include optimised indexer
    total = sum(signals(repo) .* ω_i ./ Ω)
    return total
end

#TODO: add query to get real time gas rates for each tx -> this can be connected to indexer making gas estimations
