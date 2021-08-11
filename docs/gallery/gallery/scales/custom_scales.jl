# ---
# title: Custom scales
# cover: assets/custom_scales.png
# author: "[Pietro Vertechi](https://github.com/piever)"
# ---

using AlgebraOfGraphics, CairoMakie
using Colors
set_aog_theme!() #src

# Sometimes, there is no default palettes for a specific attribute. In that
# case, the user can pass their own. TODO: allow legend to use custom attribute
# of plot, such as the arrowhead or the arrowcolor and pass correct legend symbol.

x=repeat(1:20, inner=20)
y=repeat(1:20, outer=20)
u=cos.(x)
v=sin.(y)
c=rand(Bool, length(x))
d=rand(Bool, length(x))
df = (; x, y, u, v, c, d)
colors = [colorant"#E24A33", colorant"#348ABD"]
heads = ['▲', '●']
plt = data(df) *
    mapping(:x, :y, :u, :v) *
    mapping(arrowhead=:c => nonnumeric) *
    mapping(arrowcolor=:d => nonnumeric) *
    visual(Arrows, arrowsize=10, lengthscale=0.3)
draw(plt; palettes=(arrowcolor=colors, arrowhead=heads))

# To associate specific attribute values to specific data values, use pairs.
# Missing keys will cycle over values that are not pairs.

x = rand(100)
y = rand(100)
z = rand(["a", "b", "c", "d"], 100)
df = (; x, y, z)
plt = data(df) * mapping(:x, :y, color=:z)
colors = ["a" => colorant"#E24A33", "c" => colorant"#348ABD", colorant"#988ED5", colorant"#777777"]
fg = draw(plt; palettes=(color=colors,))

# save cover image #src
mkpath("assets") #src
save("assets/custom_scales.png", fg) #src
