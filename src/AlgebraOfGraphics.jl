module AlgebraOfGraphics

using Base: front, tail
using Dates
using Tables: rows, columns, getcolumn, columnnames
using StructArrays: StructArrays, components, uniquesorted, GroupPerm, StructArray
using Colors: RGB, RGBA, red, green, blue, Color
using PlotUtils: optimize_datetime_ticks
using AbstractPlotting
using AbstractPlotting: current_default_theme, to_value, automatic, Automatic, PlotFunc, ATTRIBUTES
import AbstractPlotting.MakieLayout: hidexdecorations!,
                                     hideydecorations!,
                                     hidedecorations!,
                                     linkaxes!,
                                     linkxaxes!,
                                     linkyaxes!
using GridLayoutBase: determinedirsize, Col, Row
using PooledArrays: PooledArray
using KernelDensity: kde, pdf
using StatsBase: fit, histrange, Histogram, normalize, weights, AbstractWeights, sturges
using DataAPI: refarray

import GLM, Loess
import FileIO

export hideinnerdecorations!, deleteemptyaxes!
export arguments, Entry, Entries, AxisEntries
export renamer, nonnumeric
export density, histogram, linear, smooth, expectation, frequency
export visual, data, dims, mapping
export draw, draw!
export facet!
export set_aog_theme!

include("theme.jl")
include("scales.jl")
include("entries.jl")
include("utils.jl")
include("facet.jl")
include("helpers.jl")
include("algebra/layer.jl")
include("algebra/layers.jl")
include("algebra/processing.jl")
include("recipes/linesfill.jl")
include("transformations/splitapply.jl")
include("transformations/visual.jl")
include("transformations/linear.jl")
include("transformations/smooth.jl")
include("transformations/density.jl")
include("transformations/histogram.jl")
include("transformations/groupreduce.jl")
include("transformations/frequency.jl")
include("transformations/expectation.jl")
include("guides/legendelements.jl")
include("guides/legend.jl")

end
