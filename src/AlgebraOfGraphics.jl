module AlgebraOfGraphics

using Tables: columns, getcolumn, columnnames
using CategoricalArrays: categorical, levelcode
using Observables: AbstractObservable, Observable, to_value
using OrderedCollections: OrderedDict, LittleDict
using NamedDims: NamedDimsArray, dimnames
using StructArrays: GroupPerm, refine_perm!, StructArray
using AbstractPlotting: Point2f0
import GLM, Loess

export style, spec, data, dims, draw, categorical

include("algebraic_dict.jl")
include("context.jl")
include("specs.jl")
include("scales.jl")
include("utils.jl")
include("analysis/smooth.jl")
include("makielayout_integration.jl")

end # module
