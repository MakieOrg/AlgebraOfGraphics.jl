# Multiple color scales

````@example multiple_color_scales
using AlgebraOfGraphics, CairoMakie
````

Continuous and discrete color scales can coexist in the same plot.
This should be used sparingly, as it can make the plot harder to interpret.

````@example multiple_color_scales
x = range(-π, π, length=100)
y = sin.(x)
ŷ = y .+ randn.() .* 0.1
z = cos.(x)
c = rand(["a", "b"], 100)
df = (; x, y, ŷ, z, c)
layers = mapping(:y, color=:z) * visual(Lines) + mapping(:ŷ => "y", color=:c)
plt = data(df) * mapping(:x) * layers
fg = draw(plt)
````



