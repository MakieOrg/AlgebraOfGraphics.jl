module AlgebraOfGraphics

using StructArrays: uniquesorted,
                    finduniquesorted,
                    fieldarrays,
                    StructArray

using Tables: columns, getcolumn, columnnames, istable
using PooledArrays: PooledArray, PooledVector
using DataAPI: refarray, refvalue
using Observables: Observable, to_value
using DataStructures: OrderedDict, LinkedList, Nil, list, cons, tail
using NamedDims: NamedDimsArray, dimnames
using Requires: @require

include("utils.jl")
include("tree.jl")
include("context.jl")
include("specs.jl")

function __init__()
    @require AbstractPlotting="537997a7-5e4e-5d89-9595-2241ea00577e" begin
        @require MakieLayout="5a521ce4-ebb9-4793-b5b7-b334dfe8393c" begin
            include("makielayout_integration.jl")
        end
    end
end

end # module
