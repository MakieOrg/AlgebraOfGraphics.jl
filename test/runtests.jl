using AlgebraOfGraphics, Makie, Test
using AlgebraOfGraphics: Sorted
using AlgebraOfGraphics: separate
using AlgebraOfGraphics: Arguments, NamedArguments

using Random
Random.seed!(1234)

using KernelDensity: kde, pdf

include("utils.jl")
include("algebra.jl")
include("analyses.jl")
include("helpers.jl")
include("legend.jl")
