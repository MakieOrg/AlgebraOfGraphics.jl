# ---
# title: Regression plots
# cover: assets/regression_plot.png
# description: Linear and nonlinear regressions
# author: "[Pietro Vertechi](https://github.com/piever)"
# ---

using AlgebraOfGraphics, CairoMakie
using AlgebraOfGraphics: density
set_aog_theme!() #src

x = rand(100)
y = @. randn() + x
df = (; x, y)
xy = data(df) * mapping(:x, :y)
layers = linear() + visual(Scatter)
draw(layers * xy)

#

x = rand(100)
y = @. randn() + 5 * x ^ 2
df = (; x, y)
xy = data(df) * mapping(:x, :y)
layers = smooth() + visual(Scatter)
fg = draw(layers * xy)

# save cover image #src
mkpath("assets") #src
save("assets/regression_plot.png", fg) #src
