# ---
# title: Custom scales
# cover: assets/custom_scales.png
# description: Custom palettes and custom attributes
# author: "[Pietro Vertechi](https://github.com/piever)"
# ---

using AlgebraOfGraphics, CairoMakie
using Colors
set_aog_theme!() #src


# A pallette maps particular values to particular attribute specifications (e.g.
# 1 maps to green, 2 maps to red). Sometimes, there is no default pallettes for a
# specific attribute, and you will need to specify it manually, but there are
# sensible default pallettes for many attributes. In either case you can always
# manually specify the pallette used for a particular attribute.

# TODO: allow legend to use custom attribute of plot, such as the arrowhead or
# the arrowcolor and pass correct legend symbol.

# !!! note

#    A related concept (from Makie) is a colormap, which maps a continuous space
#    of numbers to a sequence of colors. For discrete colors you will want to
#    employ a pallette, not a colormap, because discrete values are mapped to
#    colors within AlgebraOfGraphics. AlgebraOfGraphics doesn't directly handle
#    continuous colors: this is a feature of the underlying Makie plots.
#    Pallettes and colormaps are also distinct in that a single colormap is
#    defined for an entire figure, while pallettes can vary by layer.

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
draw(plt; palettes=(color=colors,))

# Categorical color gradients can also be passed to `palettes`.

x = rand(200)
y = rand(200)
z = rand(["a", "b", "c", "d", "e", "f", "g", "h"], 200)
df = (; x, y, z)
plt = data(df) * mapping(:x, :y, color=:z)
colors = cgrad(:cividis, 8, categorical=true)
fg = draw(plt; palettes=(color=colors,))

# save cover image #src
mkpath("assets") #src
save("assets/custom_scales.png", fg) #src
