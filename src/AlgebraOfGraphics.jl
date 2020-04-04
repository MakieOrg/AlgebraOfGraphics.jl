module AlgebraOfGraphics

using Tables: columns, getcolumn, columnnames
using PooledArrays: PooledArray, PooledVector, RefArray
using DataAPI: refarray, refvalue
using Observables: AbstractObservable, Observable, to_value
using OrderedCollections: OrderedDict, LittleDict
using NamedDims: NamedDimsArray, dimnames
using StructArrays: finduniquesorted, StructArray
import GLM, Loess

export group, style, data, spec, dims, draw

include("context.jl")
include("specs.jl")
include("utils.jl")
include("analysis/smooth.jl")
include("makielayout_integration.jl")

function draw end

end # module
