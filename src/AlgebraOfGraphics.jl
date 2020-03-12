module AlgebraOfGraphics

using Base: front, tail, setindex
import Base: +, *
using StructArrays: finduniquesorted, StructArray
using Tables: columntable, columns, columnnames

include("atoms.jl")
include("utils.jl")
include("algebra.jl")
include("traces.jl")

end # module
