using AlgebraOfGraphics, Makie, Random, Statistics, Test, Dates

using AlgebraOfGraphics: Sorted
using AlgebraOfGraphics: separate
using AlgebraOfGraphics: midpoints
using AlgebraOfGraphics: compute_palettes, apply_palette
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

using Dictionaries: Indices

using KernelDensity: kde, pdf
using StatsBase: fit, histrange, Histogram, weights
using GLM: GLM
using Loess: Loess

import Shapefile, GeometryBasics

Random.seed!(1234)

include("utils.jl")
include("algebra.jl")
include("analyses.jl")
include("scales.jl")
include("helpers.jl")
include("facet.jl")
include("legend.jl")
include("geometry.jl")
include("paginate.jl")
