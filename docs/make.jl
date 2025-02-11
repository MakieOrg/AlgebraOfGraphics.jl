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
            "generated/penguins.md",
        ],
        "Examples" => [
            "Basic Visualizations" => [
                "examples/basic_visualizations/lines_and_markers.md",
                "examples/basic_visualizations/statistical_visualizations.md",
            ],
            "Data Manipulations" => [
                "examples/data_manipulations/new_columns_on_the_fly.md",
                "examples/data_manipulations/no_data.md",
                "examples/data_manipulations/pre_grouped_data.md",
                "examples/data_manipulations/presorted_data.md",
                "examples/data_manipulations/wide_data.md",
            ],
            "Scales" => [
                "examples/scales/continuous_scales.md",
                "examples/scales/custom_scales.md",
                "examples/scales/discrete_scales.md",
                "examples/scales/dodging.md",
                "examples/scales/legend_merging.md",
                "examples/scales/multiple_color_scales.md",
                "examples/scales/prescaled_data.md",
                "examples/scales/secondary_scales.md",
                "examples/scales/split_scales_facet.md",
            ],
            "Statistical Analyses" => [
                "examples/statistical_analyses/density_plots.md",
                "examples/statistical_analyses/histograms.md",
                "examples/statistical_analyses/regression_plots.md",
            ],
            "Customization" => [
                "examples/customization/axis.md",
                "examples/customization/colorbar.md",
                "examples/customization/figure.md",
                "examples/customization/legend.md",
            ],
            "Layout" => [
                "examples/layout/faceting.md",
                "examples/layout/nested_layouts.md",
            ],
            "Applications" => [
                "examples/applications/geographic.md",
                "examples/applications/geometries.md",
                "examples/applications/time_series.md",
            ],
        ],
        "Explanations" => [
            "layers/introduction.md",
            "layers/data.md",
            "layers/mapping.md",
            "generated/visual.md",
            "generated/analyses.md",
            "layers/operations.md",
            "layers/draw.md",
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
    warnonly=false,
)

deploydocs(;
    repo="github.com/MakieOrg/AlgebraOfGraphics.jl",
    push_preview=true,
)
