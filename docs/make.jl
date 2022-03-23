using AllocationOpt
using Documenter

DocMeta.setdocmeta!(AllocationOpt, :DocTestSetup, :(using AllocationOpt); recursive=true)

makedocs(;
    modules=[AllocationOpt],
    authors="The Graph Foundation",
    repo="https://github.com/anirudh2/AllocationOpt.jl/blob/{commit}{path}#{line}",
    sitename="AllocationOpt.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://anirudh2.github.io/AllocationOpt.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/anirudh2/AllocationOpt.jl",
)
