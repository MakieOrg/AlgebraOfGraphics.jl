using AlgebraOfGraphics, Makie, Random, Statistics, Test, Dates

using AlgebraOfGraphics: Sorted, Presorted
using AlgebraOfGraphics: separate
using AlgebraOfGraphics: midpoints
using AlgebraOfGraphics: apply_palette
using AlgebraOfGraphics: datavalues
using AlgebraOfGraphics: categoricalscales, CategoricalScale, fitscale, datetime2float, datetimeticks
using AlgebraOfGraphics: extrema_finite, nested_extrema_finite
using AlgebraOfGraphics: get_layout
using AlgebraOfGraphics: clean_facet_attributes
using AlgebraOfGraphics: consistent_xlabels, consistent_ylabels, colwise_consistent_xlabels, rowwise_consistent_ylabels
using AlgebraOfGraphics: col_labels!, row_labels!, panel_labels!, span_xlabel!, span_ylabel!
using AlgebraOfGraphics: compute_axes_grid
using AlgebraOfGraphics: Arguments, MixedArguments, NamedArguments
using AlgebraOfGraphics: FigureGrid
using AlgebraOfGraphics: Layer, Layers, ProcessedLayer, ProcessedLayers

using Makie: automatic
using GridLayoutBase: Protrusion

using Dictionaries: Indices, Dictionary

using KernelDensity: kde, pdf
using StatsBase: fit, histrange, Histogram, weights
using GLM: GLM
using Loess: Loess

import Shapefile, GeometryBasics
import Unitful
import DynamicQuantities
const U = Unitful
const D = DynamicQuantities
import DataFrames

Random.seed!(1234)

# This can be removed for `@test_throws` once CI only uses Julia 1.8 and up
macro test_throws_message(message::String, exp)
    return quote
        threw_exception = false
        try
            $(esc(exp))
        catch e
            msg = sprint(Base.showerror, e)
            threw_exception = true
            @test occursin($message, msg)
        end
        @test threw_exception
    end
end

include("reference_tests_utils.jl")

include("utils.jl")
include("visual.jl")
include("algebra.jl")
include("analyses.jl")
include("scales.jl")
include("helpers.jl")
include("facet.jl")
include("legend.jl")
include("geometry.jl")
include("paginate.jl")

@testset "Reference tests" begin
    include("reference_tests.jl")
end
