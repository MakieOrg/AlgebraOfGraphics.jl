# ---
# title: Lines and Markers
# cover: assets/lines_and_markers.png
# author: "[Pietro Vertechi](https://github.com/piever)"
# ---

# ### A simple scatter plot

using AlgebraOfGraphics, CairoMakie
set_aog_theme!() #src

df = (x=rand(100), y=rand(100))
xy = data(df) * mapping(:x, :y)
draw(xy)

# ### A simple lines plot

x = range(-π, π, length=100)
y = sin.(x)
df = (; x, y)
xy = data(df) * mapping(:x, :y)
layer = visual(Lines)
draw(layer * xy)

# ### Lines and scatter combined plot

x = range(-π, π, length=100)
y = sin.(x)
df = (; x, y)
xy = data(df) * mapping(:x, :y)
layers = visual(Scatter) + visual(Lines)
draw(layers * xy)

#

x = range(-π, π, length=100)
y = sin.(x)
df1 = (; x, y)
df2 = (x=rand(10), y=rand(10))
layers = data(df1) * visual(Lines) + data(df2) * visual(Scatter)
draw(layers * mapping(:x, :y))

# ### Linear regression on a scatter plot

df = (x=rand(100), y=rand(100), z=rand(100))
xy = data(df) * mapping(:x, :y)
layers = linear() + visual(Scatter) * mapping(color=:z)
fg = draw(layers * xy)


# save cover image #src
mkpath("assets") #src
save("assets/lines_and_markers.png", fg) #src
