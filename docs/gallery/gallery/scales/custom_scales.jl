# ---
# title: Custom scales
# cover: assets/custom_scales.png
# description: Custom palettes and custom attributes.
# author: "[Pietro Vertechi](https://github.com/piever)"
# id: custom_scales
# ---

using AlgebraOfGraphics, CairoMakie
using Colors
set_aog_theme!() #src

# A palette maps categorical values to particular attribute specifications (e.g.
# the first value maps to green, the second maps to red, and so on).

x=repeat(1:20, inner=20)
y=repeat(1:20, outer=20)
u=cos.(x)
v=sin.(y)
c=rand(Bool, length(x))
d=rand(Bool, length(x))
df = (; x, y, u, v, c, d)
colors = [colorant"#E24A33", colorant"#348ABD"]
heads = ['◮', '◭']
plt = data(df) *
    mapping(:x, :y, :u, :v) *
    mapping(arrowhead = :c => nonnumeric) *
    mapping(color = :d => nonnumeric) *
    visual(Arrows, arrowsize=10, lengthscale=0.4, linewidth = 1)
fg = draw(plt, scales(Marker = (; palette = heads), Color = (; palette = colors)))

# To associate specific attribute values to specific data values, use pairs.
# Missing keys will cycle over values that are not pairs.

x = rand(100)
y = rand(100)
z = rand(["a", "b", "c", "d"], 100)
df = (; x, y, z)
plt = data(df) * mapping(:x, :y, color=:z)
colors = ["a" => :tomato, "c" => :lime, colorant"#988ED5", colorant"#777777"]
draw(plt, scales(Color = (; palette = colors)))

# Categorical color gradients can also be passed to `palettes`.

x = rand(200)
y = rand(200)
z = rand(["a", "b", "c", "d", "e", "f", "g", "h"], 200)
df = (; x, y, z)
plt = data(df) * mapping(:x, :y, color=:z)
colors = cgrad(:cividis, 8, categorical=true)
draw(plt, scales(Color = (; palette = colors)))

# save cover image #src
mkpath("assets") #src
save("assets/custom_scales.png", fg) #src
