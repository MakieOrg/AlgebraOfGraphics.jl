module AlgebraOfGraphics

using Tables: columns, getcolumn, columnnames
using CategoricalArrays: categorical, cut, levelcode, refs
using Observables: AbstractObservable, Observable, to_value
using OrderedCollections: OrderedDict, LittleDict
using NamedDims: NamedDimsArray, dimnames
using StructArrays: GroupPerm, refine_perm!, StructArray
using AbstractPlotting: Point2f0
import GLM, Loess

export data, dims, draw, spec, style
export categorical, cut

include("algebraic_dict.jl")
include("context.jl")
include("specs.jl")
include("scales.jl")
include("analysis/analysis.jl")
include("analysis/smooth.jl")
include("makielayout_integration.jl")
include("utils.jl")

end # module
