module AlgebraOfGraphics

using Tables: columns, getcolumn, columnnames
using PooledArrays: PooledArray, PooledVector, RefArray
using DataAPI: refarray, refvalue
using Observables: AbstractObservable, Observable, to_value
using OrderedCollections: OrderedDict, LittleDict
using NamedDims: NamedDimsArray, dimnames
using StructArrays: finduniquesorted, append!!, StructArray
using GeoInterface: AbstractMultiPolygon, AbstractFeatureCollection, coordinates, GeoInterface
using AbstractPlotting: Point2f0
import GLM, Loess

export style, spec, draw

include("specs.jl")
include("data.jl")
include("scales.jl")
include("utils.jl")
include("analysis/smooth.jl")
include("makielayout_integration.jl")

end # module
