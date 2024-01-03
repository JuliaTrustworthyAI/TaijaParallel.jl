using TaijaParallel
using Documenter

DocMeta.setdocmeta!(TaijaParallel, :DocTestSetup, :(using TaijaParallel); recursive=true)

makedocs(;
    modules=[TaijaParallel],
    authors="Patrick Altmeyer",
    repo="https://github.com/JuliaTrustworthyAI/TaijaParallel.jl/blob/{commit}{path}#{line}",
    sitename="TaijaParallel.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaTrustworthyAI.github.io/TaijaParallel.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaTrustworthyAI/TaijaParallel.jl",
    devbranch="main",
)
