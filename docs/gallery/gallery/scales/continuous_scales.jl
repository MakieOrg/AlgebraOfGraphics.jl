# ---
# title: Continuous scales
# cover: assets/continuous_scales.png
# description: Applying nonlinear transformations.
# author: "[Pietro Vertechi](https://github.com/piever)"
# ---

using AlgebraOfGraphics, CairoMakie
set_aog_theme!() #src

x = 1:100
y = @. sqrt(x) + 20x + 100
df = (; x, y)
plt = data(df) *
    mapping(
        :x,
        :y => log => "√x + 20x + 100 (log scale)",
    ) * visual(Lines)
draw(plt)

#

x = 1:100
y = @. sqrt(x) + 20x + 100
df = (; x, y)
plt = data(df) *
    mapping(
        :x,
        :y => "√x + 20x + 100 (log scale)",
    ) * visual(Lines)
draw(plt, axis=(yscale=log,))

#

x = 0:100
y = @. 0.01 + x/1000
df = (; x, y)
plt = data(df) *
    mapping(
        :x,
        :y => "y",
    ) * visual(Lines)
fg = draw(plt, axis=(yscale=log,))

# save cover image #src
mkpath("assets") #src
save("assets/continuous_scales.png", fg) #src
