using AlgebraOfGraphics, Makie, Random, Statistics, Test

using AlgebraOfGraphics: Sorted
using AlgebraOfGraphics: separate
using AlgebraOfGraphics: Arguments, MixedArguments, NamedArguments

using KernelDensity: kde, pdf
using StatsBase: fit, histrange, Histogram, weights

Random.seed!(1234)

include("utils.jl")
include("algebra.jl")
include("analyses.jl")
include("helpers.jl")
include("legend.jl")
