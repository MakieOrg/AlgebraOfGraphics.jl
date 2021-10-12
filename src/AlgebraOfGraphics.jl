module AlgebraOfGraphics

using Base: front, tail
using Dates
using Tables: rows, columns, getcolumn, columnnames
using StructArrays: StructArrays, components, uniquesorted, GroupPerm, StructArray
using GeometryBasics: AbstractGeometry, Polygon, MultiPolygon
using GeoInterface: coordinates, geotype
using Colors: RGB, RGBA, red, green, blue, Color
using PlotUtils: optimize_datetime_ticks, AbstractColorList
using Makie
using Makie: current_default_theme, to_value, automatic, Automatic, PlotFunc, ATTRIBUTES
import Makie.MakieLayout: hidexdecorations!,
                          hideydecorations!,
                          hidedecorations!,
                          linkaxes!,
                          linkxaxes!,
                          linkyaxes!
using GridLayoutBase: determinedirsize, Col, Row
using PooledArrays: PooledArray
using KernelDensity: kde, pdf
using StatsBase: fit, histrange, Histogram, normalize, weights, AbstractWeights, sturges

import GLM, Loess
import FileIO
import RelocatableFolders

export hideinnerdecorations!, deleteemptyaxes!
export Entry, AxisEntries
export renamer, sorter, nonnumeric, verbatim
export density, histogram, linear, smooth, expectation, frequency
export visual, data, geodata, dims, mapping
export datetimeticks
export draw, draw!
export facet!, colorbar!, legend!
export set_aog_theme!

include("theme.jl")
include("helpers.jl")
include("scales.jl")
include("entries.jl")
include("facet.jl")
include("geometry.jl")
include("algebra/layer.jl")
include("algebra/layers.jl")
include("algebra/select.jl")
include("algebra/processing.jl")
include("recipes/linesfill.jl")
include("transformations/visual.jl")
include("transformations/linear.jl")
include("transformations/smooth.jl")
include("transformations/density.jl")
include("transformations/histogram.jl")
include("transformations/groupreduce.jl")
include("transformations/frequency.jl")
include("transformations/expectation.jl")
include("guides/guides.jl")
include("guides/legendelements.jl")
include("guides/legend.jl")
include("guides/colorbar.jl")

end
