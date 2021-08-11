# ---
# title: Multiple color scales
# cover: assets/multiple_color_scales.png
# author: "[Pietro Vertechi](https://github.com/piever)"
# ---

using AlgebraOfGraphics, CairoMakie
set_aog_theme!() #src

# Normally, a unique scale is associated to each given attribute. Color is an important
# exception: continuous and discrete color scales can coexist in the same plot.
# This should be used sparingly, as it can make the plot harder to interpret.

x = range(-π, π, length=100)
y = sin.(x)
ŷ = y .+ randn.() .* 0.1
z = cos.(x)
c = rand(["a", "b"], 100)
df = (; x, y, ŷ, z, c)
layers = mapping(:y, color=:z) * visual(Lines) + mapping(:ŷ => "y", color=:c)
plt = data(df) * mapping(:x) * layers
fg = draw(plt)


# save cover image #src
mkpath("assets") #src
save("assets/multiple_color_scales.png", fg) #src
