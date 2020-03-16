module AlgebraOfGraphics

using Base: front, tail, setindex
import Base: +, *, merge
using StructArrays: uniquesorted, finduniquesorted, StructArray
using Tables: columntable
using PooledArrays: PooledArray, PooledVector
using DataAPI: refarray, refvalue
import OrderedCollections: OrderedDict

include("spec.jl")
include("algebra.jl")
include("utils.jl")

end # module
