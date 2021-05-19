using AlgebraOfGraphics
using Documenter
using Literate, Glob
using CairoMakie
using Random

Random.seed!(1234)

CairoMakie.activate!(type="svg")

ENV["DATADEPS_ALWAYS_ACCEPT"] = true

# generate examples
GENERATED = joinpath(@__DIR__, "src", "generated")
SOURCE_FILES = Glob.glob("*.jl", GENERATED)
foreach(fn -> Literate.markdown(fn, GENERATED), SOURCE_FILES)

DocMeta.setdocmeta!(AlgebraOfGraphics, :DocTestSetup, :(using AlgebraOfGraphics); recursive=true)

makedocs(;
    modules=[AlgebraOfGraphics],
    authors="Pietro Vertechi <pietro.vertechi@veos.digital>",
    repo="https://github.com/JuliaPlots/AlgebraOfGraphics.jl/blob/{commit}{path}#{line}",
    sitename="Algebra of Graphics",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        assets=["assets/favicon.ico"],
    ),
    pages=Any[
        "Home" => "index.md",
        "Getting Started" => [
            "generated/penguins.md",
            "generated/gallery.md",
        ],
        "Algebra of Layers" => [
            "layers/introduction.md",
            "layers/data.md",
            "layers/mappings.md",
            "Transformations" => [
                "generated/visualtransformations.md",
                "generated/datatransformations.md",
            ],
            "layers/operations.md",
            "layers/draw.md",
        ],
        "Internals" => [
            "generated/entries.md",
        ],
        "API.md",
        "philosophy.md",
    ],
    strict = true,
)

deploydocs(;
    repo="github.com/JuliaPlots/AlgebraOfGraphics.jl",
    push_preview = true,
)
