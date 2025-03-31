using AlgebraOfGraphics, CairoMakie
using Colors

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

x = rand(100)
y = rand(100)
z = rand(["a", "b", "c", "d"], 100)
df = (; x, y, z)
plt = data(df) * mapping(:x, :y, color=:z)
colors = ["a" => colorant"#E24A33", "c" => colorant"#348ABD", colorant"#988ED5", colorant"#777777"]
draw(plt; palettes=(color=colors,))

x = rand(200)
y = rand(200)
z = rand(["a", "b", "c", "d", "e", "f", "g", "h"], 200)
df = (; x, y, z)
plt = data(df) * mapping(:x, :y, color=:z)
colors = cgrad(:cividis, 8, categorical=true)
fg = draw(plt; palettes=(color=colors,))

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

