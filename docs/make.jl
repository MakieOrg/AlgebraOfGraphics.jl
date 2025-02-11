using AlgebraOfGraphics
using Documenter
using DocumenterVitepress
using Literate, Glob
using CairoMakie

CairoMakie.activate!(type="svg")

ENV["DATADEPS_ALWAYS_ACCEPT"] = true

DocMeta.setdocmeta!(AlgebraOfGraphics, :DocTestSetup, :(using AlgebraOfGraphics); recursive=true)

cp(joinpath(@__DIR__, "..", "CHANGELOG.md"), joinpath(@__DIR__, "src", "changelog.md"), force = true)

makedocs(;
    modules=[AlgebraOfGraphics],
    authors="Pietro Vertechi",
    repo="https://github.com/MakieOrg/AlgebraOfGraphics.jl",
    sitename="Algebra of Graphics",
    format = DocumenterVitepress.MarkdownVitepress(;
        repo = "https://github.com/MakieOrg/AlgebraOfGraphics.jl",
        deploy_url = "https://aog.makie.org",
    ),
    pages=Any[
        "Home" => "index.md",
        "Tutorials" => [
            "tutorials/getting-started.md",
        ],
        "Examples" => [
            "Basic Visualizations" => [
                "examples/basic-visualizations/lines-and-markers.md",
                "examples/basic-visualizations/statistical-visualizations.md",
            ],
            "Data Manipulations" => [
                "examples/data-manipulations/new-columns-on-the-fly.md",
                "examples/data-manipulations/no-data.md",
                "examples/data-manipulations/pre-grouped-data.md",
                "examples/data-manipulations/presorted-data.md",
                "examples/data-manipulations/wide-data.md",
            ],
            "Scales" => [
                "examples/scales/continuous-scales.md",
                "examples/scales/custom-scales.md",
                "examples/scales/discrete-scales.md",
                "examples/scales/dodging.md",
                "examples/scales/legend-merging.md",
                "examples/scales/multiple-color-scales.md",
                "examples/scales/prescaled-data.md",
                "examples/scales/secondary-scales.md",
                "examples/scales/split-scales-facet.md",
            ],
            "Statistical Analyses" => [
                "examples/statistical-analyses/density-plots.md",
                "examples/statistical-analyses/histograms.md",
                "examples/statistical-analyses/regression-plots.md",
            ],
            "Customization" => [
                "examples/customization/axis.md",
                "examples/customization/colorbar.md",
                "examples/customization/figure.md",
                "examples/customization/legend.md",
            ],
            "Layout" => [
                "examples/layout/faceting.md",
                "examples/layout/nested-layouts.md",
            ],
            "Applications" => [
                "examples/applications/geographic.md",
                "examples/applications/geometries.md",
                "examples/applications/time-series.md",
            ],
        ],
        "Explanations" => [
            "explanations/introduction.md",
            "explanations/data.md",
            "explanations/mapping.md",
            "explanations/visual.md",
            "explanations/analyses.md",
            "explanations/operations.md",
            "explanations/draw.md",
        ],
        "Resources" => [
            "FAQs.md",
            "philosophy.md",
            "changelog.md",
            "API" => [
                "API/types.md",
                "API/functions.md",
                "API/recipes.md",
            ],
        ],
    ],
    warnonly=get(ENV, "CI", "false") != "true",
    pagesonly = true,
)

deploydocs(;
    repo="github.com/MakieOrg/AlgebraOfGraphics.jl",
    push_preview=true,
)
