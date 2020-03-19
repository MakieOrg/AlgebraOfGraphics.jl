module AlgebraOfGraphics

using Base: front, tail, setindex
import Base: +, *, ^, merge
using StructArrays: uniquesorted, finduniquesorted, fieldarrays, StructArray
using Tables: columntable
using PooledArrays: PooledArray, PooledVector
using DataAPI: refarray, refvalue

include("spec.jl")
include("algebra.jl")
include("utils.jl")

end # module
