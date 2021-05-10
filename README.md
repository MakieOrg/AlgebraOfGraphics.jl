# AlgebraOfGraphics

[![CI](https://github.com/JuliaPlots/AlgebraOfGraphics.jl/workflows/CI/badge.svg?branch=master)](https://github.com/JuliaPlots/AlgebraOfGraphics.jl/actions?query=workflow%3ACI+branch%3Amaster)
[![codecov.io](http://codecov.io/github/JuliaPlots/AlgebraOfGraphics.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaPlots/AlgebraOfGraphics.jl?branch=master)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](http://juliaplots.org/AlgebraOfGraphics.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](http://juliaplots.org/AlgebraOfGraphics.jl/dev)

Define an algebra of graphics based on a few simple building blocks that can be combined using `+` and `*`. Still somewhat experimental, may break often.

## Acknowledgements

Analyses rely on [StatsBase.jl](https://github.com/JuliaStats/StatsBase.jl), [Loess.jl](https://github.com/JuliaStats/Loess.jl), [KernelDensity.jl](https://github.com/JuliaStats/KernelDensity.jl), and [GLM.jl](https://github.com/JuliaStats/GLM.jl). Some of their documentation is transcribed here.

Visualizations are powered by [Makie](https://github.com/JuliaPlots/Makie.jl) and its layouting capabilities.

Automatic legend creation re-implements the machinery in [TabularMakie](https://github.com/greimel/TabularMakie.jl).

Logo and favicon made with 🧡 by @dyogurt.