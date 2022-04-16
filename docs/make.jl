using AlgebraOfGraphics
using Documenter
using Literate, Glob
using CairoMakie
using DemoCards

CairoMakie.activate!(type="svg")

ENV["DATADEPS_ALWAYS_ACCEPT"] = true

# generate examples
GENERATED = joinpath(@__DIR__, "src", "generated")
SOURCE_FILES = Glob.glob("*.jl", GENERATED)
foreach(fn -> Literate.markdown(fn, GENERATED), SOURCE_FILES)

DocMeta.setdocmeta!(AlgebraOfGraphics, :DocTestSetup, :(using AlgebraOfGraphics); recursive=true)

gallery, postprocess_cb, gallery_assets = makedemos("gallery")

makedocs(;
    modules=[AlgebraOfGraphics],
    authors="Pietro Vertechi",
    repo="https://github.com/JuliaPlots/AlgebraOfGraphics.jl/blob/{commit}{path}#{line}",
    sitename="Algebra of Graphics",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        assets=["assets/favicon.ico", gallery_assets],
    ),
    pages=Any[
        "Home" => "index.md",
        "Getting Started" => [
            "generated/penguins.md",
            gallery
        ],
        "Algebra of Layers" => [
            "layers/introduction.md",
            "layers/data.md",
            "layers/mapping.md",
            "generated/visual.md",
            "generated/analyses.md",
            "layers/operations.md",
            "layers/draw.md",
        ],
        "Internals" => [
            "generated/entries.md",
        ],
        "API" => [
            "API/types.md",
            "API/functions.md",
            "API/recipes.md",
        ],
        "FAQs.md",
        "philosophy.md",
    ],
    strict=true,
)
postprocess_cb() # redirect url for DemoCards generated files

deploydocs(;
    repo="github.com/JuliaPlots/AlgebraOfGraphics.jl",
    push_preview=true,
)
