using AllocationOpt
using Documenter

DocMeta.setdocmeta!(AllocationOpt, :DocTestSetup, :(using AllocationOpt); recursive=true)

makedocs(;
    modules=[AllocationOpt],
    authors="The Graph Foundation",
    repo="https://github.com/graphprotocol/allocation-optimizer/blob/{commit}{path}#{line}",
    sitename="allocation-optimizer",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://graphprotocol.github.io/allocation-optimizer",
        edit_link="main",
        assets=String[],
    ),
    pages=["Home" => "index.md", "API Reference" => "api.md"],
)

deploydocs(;
    repo="github.com/graphprotocol/allocation-optimizer", devbranch="main", devurl="latest"
)
