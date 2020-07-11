module AlgebraOfGraphics

using Tables: columns, getcolumn, columnnames
using CategoricalArrays: categorical, cut, levelcode, refs, levels
using Observables: AbstractObservable, Observable, to_value
using OrderedCollections: OrderedDict
using NamedDims: NamedDimsArray, dimnames
using StructArrays: GroupPerm, refine_perm!, StructArray
using AbstractPlotting: Point2f0, AbstractPlotting
using KernelDensity: kde
import GLM, Loess

export data, dims, draw, spec, style
export categorical, cut

include("algebraic_list.jl")
include("context.jl")
include("specs.jl")
include("scales.jl")
include("analysis/analysis.jl")
include("analysis/smooth.jl")
include("analysis/density.jl")
# include("makielayout_integration.jl")
include("utils.jl")

end # module
