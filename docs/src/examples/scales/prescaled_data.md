# Pre-scaled data

````@example prescaled_data
using AlgebraOfGraphics, CairoMakie
using Colors

x = rand(100)
y = rand(100)
z = rand([colorant"teal", colorant"orange"], 100)
df = (; x, y, z)
plt = data(df) * mapping(:x, :y, color=:z => verbatim)
draw(plt)
````

Plotting labels instead of markers

````@example prescaled_data
x = rand(100)
y = rand(100)
label = rand(["a", "b"], 100)
df = (; x, y, label)
plt = data(df) * mapping(:x, :y, text=:label => verbatim) * visual(Makie.Text)
fg = draw(plt)
````



