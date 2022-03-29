export optimize

function optimize(optimize_id, repository::Repository, whitelist, blacklist)
    if !isnothing(whitelist) && !isnothing(blacklist)
        throw(ArgumentError("whitelist and blacklist cannot both be specified"))
    end
end
