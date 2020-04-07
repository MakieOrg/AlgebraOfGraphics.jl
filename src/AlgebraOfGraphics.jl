module AlgebraOfGraphics

using Tables: columns, getcolumn, columnnames
using PooledArrays: PooledArray, PooledVector, RefArray
import DataAPI
using Observables: AbstractObservable, Observable, to_value
using OrderedCollections: OrderedDict, LittleDict
using NamedDims: NamedDimsArray, dimnames
using StructArrays: GroupPerm, refine_perm!, StructArray
using GeoInterface: AbstractMultiPolygon, AbstractFeatureCollection, coordinates, GeoInterface
using AbstractPlotting: Point2f0
import GLM, Loess

export style, spec, data, dims, draw

include("context.jl")
include("specs.jl")
include("scales.jl")
include("utils.jl")
include("analysis/smooth.jl")
include("makielayout_integration.jl")

end # module
