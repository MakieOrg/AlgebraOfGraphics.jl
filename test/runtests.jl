using AlgebraOfGraphics, Makie, Random, Statistics, Test

using AlgebraOfGraphics: Sorted
using AlgebraOfGraphics: separate
using AlgebraOfGraphics: midpoints
using AlgebraOfGraphics: Arguments, MixedArguments, NamedArguments

using Dictionaries: Indices

using KernelDensity: kde, pdf
using StatsBase: fit, histrange, Histogram, weights
using GLM: GLM
using Loess: Loess

Random.seed!(1234)

include("utils.jl")
include("algebra.jl")
include("analyses.jl")
include("helpers.jl")
include("legend.jl")
