using MiniMPI
using Documenter

DocMeta.setdocmeta!(MiniMPI, :DocTestSetup, :(using MiniMPI); recursive=true)

makedocs(;
    modules=[MiniMPI],
    authors="Renato Zimmermann",
    repo="https://github.com/renatomatz/MiniMPI.jl/blob/{commit}{path}#{line}",
    sitename="MiniMPI.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://renatomatz.github.io/MiniMPI.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/renatomatz/MiniMPI.jl",
    devbranch="main",
)
