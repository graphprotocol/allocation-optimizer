export calculate_gas_fee, sum_gas_fee, estimated_profit

function calculate_gas_fee(allocs::Dict{String, Float64}, txGas)
    sum(map(x -> x > 0 ? txGas : 0, values(allocs)))
end

function sum_gas_fee(allocs::Dict{String, Float64}, txGas)
    # open + close + claim
    calculate_gas_fee(allocs, txGas) + calculate_gas_fee(allocs, txGas) + calculate_gas_fee(allocs, 0.3 * txGas)
end

function estimated_profit(repo::Repository, allocs::Dict{String, Float64}, txGas)
    repository = Repository(repo.indexers, filter(x -> x.id in keys(allocs) ,repo.subgraphs))
    rewards(repository, allocs) - sum_gas_fee(allocs, txGas)
end

function rewards(repo::Repository, allocs::Dict{String, Float64})
    total = 0
    for (id, amount) in allocs
        total += signals(repo, id) * amount / (allocations(repo, id) + amount)
    end
    total
end

#TODO: add query to get real time gas rates for each tx -> this can be connected to indexer making gas estimations
