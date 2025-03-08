````@raw html
---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  name: AlgebraOfGraphics
  text:
  tagline: An algebraic spin on grammar-of-graphics data visualization powered by Makie.jl
  image:
    src: logo.svg
    alt: AlgebraOfGraphics
  actions:
    - theme: brand
      text: Getting started
      link: /tutorials/getting-started
    - theme: alt
      text: View on Github
      link: https://github.com/MakieOrg/AlgebraOfGraphics.jl
---
````

# Welcome to AlgebraOfGraphics!

AlgebraOfGraphics (AoG) defines a language for data visualization, inspired by the grammar-of-graphics system made popular by the R library [ggplot2](https://ggplot2.tidyverse.org/). It is based on the plotting package [Makie.jl](https://docs.makie.org/stable/) which means that most capabilities of Makie are available, and AoG plots can be freely composed with normal Makie figures.

## Example

In AlgebraOfGraphics, a few simple building blocks can be combined using `+` and `*` to quickly create complex visualizations, like this:

```@example
using AlgebraOfGraphics, CairoMakie, PalmerPenguins, DataFrames

penguins = DataFrame(AlgebraOfGraphics.penguins())
set_aog_theme!() # hide
update_theme!(Axis = (; width = 120, height = 120)) # hide

spec =
    data(penguins) *
    mapping(
        :bill_length_mm => "Bill length (mm)",
        :bill_depth_mm => "Bill depth (mm)",
        color = :species => "Species",
        row = :sex,
        col = :island,
    ) *
    (visual(Scatter, alpha = 0.3) + linear())

draw(spec)
save("demo_hero.png", current_figure()) # hide
nothing # hide
```

````@raw html
<img src="./demo_hero.png" style="max-width: 640px; width: 100%; height: auto;">
````

## Installation

You can install AlgebraOfGraphics from the General Registry with the usual Pkg commands:

```julia
using Pkg
Pkg.add("AlgebraOfGraphics")
```

## First steps

Have a look at the [Intro to AoG - I - Fundamentals](@ref) tutorial to get to know AlgebraOfGraphics!
