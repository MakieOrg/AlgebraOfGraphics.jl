# ---
# title: Pre-scaled data
# cover: assets/prescaled_data.png
# description: Pass data to the plot as is.
# author: "[Pietro Vertechi](https://github.com/piever)"
# ---

using AlgebraOfGraphics, CairoMakie
using Colors
set_aog_theme!() #src

x = rand(100)
y = rand(100)
z = rand([colorant"teal", colorant"orange"], 100)
df = (; x, y, z)
plt = data(df) * mapping(:x, :y, color=:z => verbatim)
draw(plt)

# Plotting labels instead of markers

x = rand(100)
y = rand(100)
label = rand(["a", "b"], 100)
df = (; x, y, label)
plt = data(df) * mapping(:x, :y, text=:label => verbatim) * visual(Makie.Text)
fg = draw(plt)


# save cover image #src
mkpath("assets") #src
save("assets/prescaled_data.png", fg) #src
