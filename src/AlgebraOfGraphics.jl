module AlgebraOfGraphics

using StructArrays: uniquesorted,
                    finduniquesorted,
                    fieldarrays,
                    StructArray

using Tables: columns, getcolumn, columnnames, istable
using PooledArrays: PooledArray, PooledVector
using DataAPI: refarray, refvalue
using Observables: Observable, to_value
using DataStructures: OrderedDict, LinkedList, Nil, list, tail
using Requires: @require

include("utils.jl")
include("tree.jl")
include("trace.jl")
include("series.jl")

function __init__()
    @require AbstractPlotting="537997a7-5e4e-5d89-9595-2241ea00577e" begin
        include("makie_integration.jl")
    end
end

end # module
