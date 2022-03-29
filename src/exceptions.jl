export UnknownIndexerError, UnknownSubgraphError

struct UnknownIndexerError <: Exception
    id::String
end

Base.showerror(io::IO, e::UnknownIndexerError) = print(io, e.id, " is not a valid indexer.")


struct UnknownSubgraphError <: Exception
    id::String
end

Base.showerror(io::IO, e::UnknownSubgraphError) = print(io, e.id, " is not a valid subgraph.")
