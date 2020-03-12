module AlgebraOfGraphics

using Base: front, tail, setindex
using StructArrays: finduniquesorted, StructArray
using Tables: columntable

include("atoms.jl")
include("utils.jl")
include("algebra.jl")
include("traces.jl")

end # module
