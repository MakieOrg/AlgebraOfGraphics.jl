module AlgebraOfGraphics

using Base: front, tail, setindex
import Base: +, *, ^, merge
using StructArrays: uniquesorted, finduniquesorted, fieldarrays, StructArray
using Tables: columntable
using PooledArrays: PooledArray, PooledVector
using DataAPI: refarray, refvalue
using Observables: Observable
using Requires: @require

include("trace.jl")
include("utils.jl")
include("context.jl")

function __init__()
    @require AbstractPlotting="537997a7-5e4e-5d89-9595-2241ea00577e" begin
        include("makie_integration.jl")
    end
end

end # module
