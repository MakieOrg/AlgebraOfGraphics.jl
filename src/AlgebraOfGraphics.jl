module AlgebraOfGraphics

using Base: front, tail, setindex
import Base: +, *
using StructArrays: finduniquesorted, StructArray
using Tables: columntable, columns, columnnames
using PooledArrays: PooledArray, PooledVector
using DataAPI: refarray, refvalue

include("atoms.jl")
include("utils.jl")
include("algebra.jl")
include("traces.jl")

end # module
