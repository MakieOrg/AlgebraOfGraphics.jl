module AlgebraOfGraphics

using Base: front, tail, setindex
import Base: +, *, get, merge
using StructArrays: finduniquesorted, StructArray
using Tables: columntable, columns, columnnames
using PooledArrays: PooledArray, PooledVector
using DataAPI: refarray, refvalue

include("algebra.jl")
include("atoms.jl")
include("utils.jl")

end # module
