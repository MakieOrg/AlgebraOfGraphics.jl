module AlgebraOfGraphics

using StructArrays: uniquesorted,
                    finduniquesorted,
                    fieldarrays,
                    StructArray

using Tables: columns, getcolumn, columnnames, istable
using PooledArrays: PooledArray, PooledVector, RefArray
using DataAPI: refarray, refvalue
using Observables: AbstractObservable, Observable, to_value
using OrderedCollections: OrderedDict
using NamedDims: NamedDimsArray, dimnames
import JSON
import GLM
using Requires: @require

include("utils.jl")
include("context.jl")
include("specs.jl")
include("analysis/smooth.jl")
include("plotlyjs_integration.jl")

function draw end

function __init__()
    @require AbstractPlotting="537997a7-5e4e-5d89-9595-2241ea00577e" begin
        @require MakieLayout="5a521ce4-ebb9-4793-b5b7-b334dfe8393c" begin
            include("makielayout_integration.jl")
        end
    end
end

end # module
