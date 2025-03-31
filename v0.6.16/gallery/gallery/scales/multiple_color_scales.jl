using AlgebraOfGraphics, CairoMakie

x = range(-π, π, length=100)
y = sin.(x)
ŷ = y .+ randn.() .* 0.1
z = cos.(x)
c = rand(["a", "b"], 100)
df = (; x, y, ŷ, z, c)
layers = mapping(:y, color=:z) * visual(Lines) + mapping(:ŷ => "y", color=:c)
plt = data(df) * mapping(:x) * layers
fg = draw(plt)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

