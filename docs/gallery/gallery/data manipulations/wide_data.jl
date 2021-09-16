# ---
# title: Wide data
# cover: assets/wide_data.png
# description: Working with data in the wide format
# author: "[Pietro Vertechi](https://github.com/piever)"
# ---

using AlgebraOfGraphics, CairoMakie
using AlgebraOfGraphics: density
set_aog_theme!() #src

df = (a=randn(100), b=randn(100), c=randn(100))
labels = ["Trace 1", "Trace 2", "Trace 3"]
plt = data(df) *
    density() *
    mapping([:a, :b, :c] .=> "some label") *
    mapping(color=dims(1) => renamer(labels))
draw(plt)

#

df = (a=rand(100), b=rand(100), c=rand(100), d=rand(100))
labels = ["Trace One", "Trace Two", "Trace Three"]
layers = linear() + visual(Scatter)
plt = data(df) * layers * mapping(1, 2:4 .=> "value", color=dims(1) => renamer(labels))
draw(plt)

# The wide format is combined with broadcast semantics.

df = (sepal_length=rand(100), sepal_width=rand(100), petal_length=rand(100), petal_width=rand(100))
xvars = ["sepal_length", "sepal_width"]
yvars = ["petal_length" "petal_width"]
layers = linear() + visual(Scatter)
plt = data(df) * layers * mapping(xvars, yvars, col=dims(1), row=dims(2))
fg = draw(plt)

# save cover image #src
mkpath("assets") #src
save("assets/wide_data.png", fg) #src
