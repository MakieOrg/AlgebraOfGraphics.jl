module AlgebraOfGraphics

using Base.Broadcast: ArrayStyle, Broadcasted
using StructArrays: uniquesorted,
                    finduniquesorted,
                    fieldarrays,
                    StructArray

using Tables: columns, getcolumn, columnnames, istable
using PooledArrays: PooledArray, PooledVector
using DataAPI: refarray, refvalue
using Observables: Observable
using DataStructures: OrderedDict, LinkedList, list, tail, cons
using Requires: @require

include("mixedtuple.jl")
include("trace.jl")
include("tracetree.jl")
include("utils.jl")

function __init__()
    @require AbstractPlotting="537997a7-5e4e-5d89-9595-2241ea00577e" begin
        include("makie_integration.jl")
    end
end

end # module
