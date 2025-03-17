module AlgebraOfGraphics

using Base: front, tail
using Dates
using Tables: rows, columns, getcolumn, columnnames, columntable
using StructArrays: StructArrays, components, uniquesorted, GroupPerm, StructArray
using GeometryBasics: AbstractGeometry, Polygon, MultiPolygon
using GeoInterface: coordinates, isgeometry, geomtrait, PolygonTrait, MultiPolygonTrait
using Colors: RGB, RGBA, red, green, blue, Color
using PlotUtils: AbstractColorList
using Makie
using Makie: current_default_theme, to_value, automatic, Automatic, Block, ATTRIBUTES
import Makie: hidexdecorations!,
              hideydecorations!,
              hidedecorations!,
              linkaxes!,
              linkxaxes!,
              linkyaxes!
using GridLayoutBase: update!, Protrusion, protrusionsobservable
using PooledArrays: PooledArray
using Dictionaries: AbstractDictionary, Dictionary, Indices, getindices, set!, dictionary
using KernelDensity: kde, pdf
using StatsBase: fit, histrange, Histogram, normalize, sturges, StatsBase

import Accessors
import GLM, Loess
import FileIO
import RelocatableFolders
import PolygonOps
import Isoband
import NaturalSort

export hideinnerdecorations!, deleteemptyaxes!
export Layer, Layers, ProcessedLayer, ProcessedLayers, zerolayer
export Entry, AxisEntries
export renamer, sorter, nonnumeric, verbatim, presorted
export density, histogram, linear, smooth, expectation, frequency, contours, filled_contours
export visual, data, geodata, dims, mapping
export datetimeticks
export draw, draw!
export facet!, colorbar!, legend!
export set_aog_theme!
export paginate
export scale, scales
export pregrouped
export direct
export from_continuous

include("dict.jl")
include("theme.jl")
include("helpers.jl")
include("scales.jl")
include("algebra/layer.jl")
include("entries.jl")
include("facet.jl")
include("algebra/layers.jl")
include("algebra/select.jl")
include("algebra/processing.jl")
include("recipes/choropleth.jl")
include("recipes/linesfill.jl")
include("recipes/poly.jl")
include("aesthetics.jl")
include("transformations/visual.jl")
include("transformations/linear.jl")
include("transformations/smooth.jl")
include("transformations/density.jl")
include("transformations/histogram.jl")
include("transformations/groupreduce.jl")
include("transformations/frequency.jl")
include("transformations/expectation.jl")
include("transformations/contours.jl")
include("transformations/filled_contours.jl")
include("guides/guides.jl")
include("guides/legend.jl")
include("guides/colorbar.jl")
include("draw.jl")
include("paginate.jl")
include("testdata.jl")

include("precompiles.jl")

end
