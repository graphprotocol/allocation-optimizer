using AllocationOpt
using Documenter

DocMeta.setdocmeta!(AllocationOpt, :DocTestSetup, :(using AllocationOpt); recursive=true)

makedocs(;
    modules=[AllocationOpt],
    authors="The Graph Foundation",
    repo="https://github.com/graphprotocol/allocation-optimizer/blob/{commit}{path}#{line}",
    sitename="The Allocation Optimizer",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://graphprotocol.github.io/allocation-optimizer",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Configuration" => "configuration.md",
        "Usage" => [
            "provided-binary.md",
            "build-a-binary.md",
            "call-julia.md",
            "calling-another.md",
        ],
        "Understanding The Output" => "output.md",
        "API Reference" => "api.md",
        "Reporting Bugs" => "bugs.md",
        "Contributing" => "contributing.md",
    ],
)

deploydocs(;
    repo="github.com/graphprotocol/allocation-optimizer", devbranch="main", devurl="latest"
)
