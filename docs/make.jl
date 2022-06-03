using AllocationOpt
using Documenter

DocMeta.setdocmeta!(AllocationOpt, :DocTestSetup, :(using AllocationOpt); recursive=true)

makedocs(;
    modules=[AllocationOpt],
    authors="The Graph Foundation",
    repo="https://github.com/graphprotocol/AllocationOpt.jl/blob/{commit}{path}#{line}",
    sitename="AllocationOpt.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://graphprotocol.github.io/AllocationOpt.jl",
        assets=String[],
    ),
    pages=["Home" => "index.md", "Usage" => "usage.md"],
)

deploydocs(; repo="github.com/graphprotocol/AllocationOpt.jl")
