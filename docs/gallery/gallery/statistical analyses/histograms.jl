# ---
# title: Histograms
# cover: assets/histograms.png
# description: Computing 1- and 2-dimensional histograms
# author: "[Pietro Vertechi](https://github.com/piever)"
# ---

using AlgebraOfGraphics, CairoMakie
using AlgebraOfGraphics: density
set_aog_theme!() #src

df = (x=rand(0:99, 1000),)
plt = data(df) * mapping(:x) * histogram(bins=20)
fg = draw(plt)

#

df = (x=randn(1000), c=rand(["a", "b"], 1000))
plt = data(df) * mapping(:x, color=:c, stack=:c) * histogram(bins=20)
fg = draw(plt)

#

df = (x=rand(1000), y=randn(1000))
plt = data(df) * mapping(:x, :y) * histogram(bins=20)
draw(plt)


# save cover image #src
mkpath("assets") #src
save("assets/histograms.png", fg) #src
