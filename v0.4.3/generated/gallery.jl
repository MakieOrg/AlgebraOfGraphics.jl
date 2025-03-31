# # Example gallery
#
# Semi-curated collection of examples.
#
# ## Lines and markers
#
# ### A simple scatter plot

using AlgebraOfGraphics, CairoMakie
set_aog_theme!()

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
draw(layers * xy)

# ## Faceting
#
# ### Facet grid

df = (x=rand(100), y=rand(100), i=rand(["a", "b", "c"], 100), j=rand(["d", "e", "f"], 100))
plt = data(df) * mapping(:x, :y, col=:i, row=:j)
draw(plt)

# ### Facet wrap

df = (x=rand(100), y=rand(100), l=rand(["a", "b", "c", "d", "e"], 100))
plt = data(df) * mapping(:x, :y, layout=:l)
draw(plt)

# ### Embedding facets
#
# All AlgebraOfGraphics plots can be inserted in any figure position, where the rest
# of the figure is managed by vanilla Makie.
# For example

resolution = (800, 400)
fig = Figure(; resolution)
ax = Axis(fig[1, 1], title="Some plot")

df = (x=rand(100), y=rand(100), i=rand(["a", "b", "c"], 100), j=rand(["d", "e", "f"], 100))
plt = data(df) * mapping(:x, :y, col=:i, row=:j)

subfig = fig[1, 2:3]
ag = draw!(subfig, plt)
for ae in ag
    Axis(ae).xticklabelrotation[] = π/2
end
fig

# ### Adding traces to only some subplots

df1 = (x=rand(100), y=rand(100), i=rand(["a", "b", "c"], 100), j=rand(["d", "e", "f"], 100))
df2 = (x=[0, 1], y=[0.5, 0.5], i=fill("a", 2), j=fill("e", 2))
layers = data(df1) * visual(Scatter) + data(df2) * visual(Lines)
draw(layers * mapping(:x, :y, col=:i, row=:j))

# ## Statistical analyses
#
# ### Density plot

using AlgebraOfGraphics: density
df = (x=randn(1000), c=rand(["a", "b"], 1000))
plt = data(df) * mapping(:x, color=:c) * density(bandwidth=0.5)
draw(plt)

#

df = (x=randn(1000), c=rand(["a", "b"], 1000))
plt = data(df) * mapping(:x, color=:c) * density(bandwidth=0.5) * visual(orientation=:vertical)
"Not yet supported" # hide

# ## Discrete scales
#
# By default categorical ticks, as well as names from legend entries, are taken from the 
# value of the variable converted to a string. Scales can be equipped with labels to
# overwrite that

df = (x=rand(["a", "b", "c"], 100), y=rand(100))
plt = data(df) * mapping(:x, :y) * visual(BoxPlot)
draw(plt)

#

df = (x=rand(["a", "b", "c"], 100), y=rand(100))
plt = data(df) *
    mapping(
        :x => renamer("a" => "label1", "b" => "label2", "c" => "label3"),
        :y
    ) * visual(BoxPlot)
draw(plt)

# The order can also be changed by tweaking the scale

plt = data(df) *
    mapping(
        :x => renamer("b" => "label b", "a" => "label a", "c" => "label c"),
        :y
    ) * visual(BoxPlot)
draw(plt)

# ## Continuous scales

x = 1:100
y = @. sqrt(x) + 20x + 100
df = (; x, y)
plt = data(df) *
    mapping(
        :x,
        :y => log => "√x + 20x + 100 (log scale)",
    ) * visual(Lines)
draw(plt)

#

x = 1:100
y = @. sqrt(x) + 20x + 100
df = (; x, y)
plt = data(df) *
    mapping(
        :x,
        :y => "√x + 20x + 100 (log scale)",
    ) * visual(Lines)
draw(plt, axis=(yscale=log,))

#

x = 0:100
y = @. 0.01 + x/1000
df = (; x, y)
plt = data(df) *
    mapping(
        :x,
        :y => "y",
    ) * visual(Lines)
draw(plt, axis=(yscale=log,))

# ## Custom scales
#
# Sometimes, there is no default palettes for a specific attribute. In that
# case, the user can pass their own. TODO: allow legend to use custom attribute
# of plot, such as the arrowhead or the arrowcolor and pass correct legend symbol.

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

# ## Axis and figure keywords
#
# ### Axis tweaking
#
# To tweak one or more axes, simply use the `axis` keyword when plotting. For example

df = (x=rand(100), y=rand(100), z=rand(100))
layers = linear() + mapping(color=:z)
plt = data(df) * layers * mapping(:x, :y)
draw(plt, axis=(aspect=1,))

# ### Figure tweaking

df = (x=rand(100), y=rand(100), z=rand(100), c=rand(["a", "b"], 100))
xyc = data(df) * mapping(:x, :y, layout=:c)
layers = linear() + mapping(color=:z)
plt = xyc * layers
draw(plt, axis=(aspect=1,), figure=(resolution=(800, 400),))

# ## Wide data

df = (a=randn(100), b=randn(100), c=randn(100))
labels = ["Trace 1", "Trace 2", "Trace 3"]
plt = data(df) *
    density() *
    mapping([:a, :b, :c] .=> "some label") *
    mapping(color=dims(1) => renamer(labels))
draw(plt)

#

df = (a=rand(100), b=rand(100), c=rand(100), d=rand(100))
labels = ["Trace 1", "Trace 2", "Trace 3"]
layers = linear() + visual(Scatter)
plt = data(df) * layers * mapping(1, 2:4 .=> "value", color=dims(1) => renamer(labels))
draw(plt)

# The wide format is combined with broadcast semantics.

df = (sepal_length=rand(100), sepal_width=rand(100), petal_length=rand(100), petal_width=rand(100))
xvars = ["sepal_length", "sepal_width"]
yvars = ["petal_length" "petal_width"]
layers = linear() + visual(Scatter)
plt = data(df) * layers * mapping(xvars, yvars, col=dims(1), row=dims(2))
draw(plt)

# ## Time series

using Dates

x = today() - Year(1) : Day(1) : today()
y = cumsum(randn(length(x)))
z = cumsum(randn(length(x)))
df = (; x, y, z)
labels = ["series 1", "series 2", "series 3", "series 4", "series 5"]
plt = data(df) *
    mapping(:x, [:y, :z] .=> "value", color=dims(1) => renamer(labels) => "series ") *
    visual(Lines)
draw(plt)

#

x = now() - Hour(6) : Minute(1) : now()
y = cumsum(randn(length(x)))
z = cumsum(randn(length(x)))
df = (; x, y, z)
plt = data(df) *
    mapping(:x, [:y, :z] .=> "value", color=dims(1) => renamer(labels) =>"series ") *
    visual(Lines)
draw(plt)

# ## Geometries

using GeometryBasics

geometry = [Rect(Vec(i, j), Vec(1, 1)) for i in 0:7 for j in 0:7]
group = [isodd(i + j) ? "light square" : "dark square" for i in 0:7 for j in 0:7]
df = (; geometry, group)

plt = data(df) * visual(Poly) * mapping(:geometry, color = :group)
draw(plt; axis=(aspect=1,))

# ### Geographic data
#
# Antarctic coastline. Data from the SCAR Antarctic Digital Database[^1].
#
# [^1]: Gerrish, L., Fretwell, P., & Cooper, P. (2021). Medium resolution vector polygons of the Antarctic coastline (7.4) [Data set]. UK Polar Data Centre, Natural Environment Research Council, UK Research & Innovation. https://doi.org/10.5285/747e63e-9d93-49c2-bafc-cf3d3f8e5afa

## Download, extract, and load shapefile
using Shapefile, ZipFile
using Downloads: download
t = mktempdir() do dir
    url = "https://data.bas.ac.uk/download/7be3ab29-7caa-46b8-a355-2e3233796e86"
    r = ZipFile.Reader(seekstart(download(url, IOBuffer())))
    for f in r.files
        open(joinpath(dir, f.name), write = true) do io
            write(io, read(f, String));
        end
    end
    Shapefile.Table(joinpath(dir, "add_coastline_medium_res_polygon_v7_4.shp"))
end

## Draw map
plt = geodata(t) * mapping(:geometry, color = :surface) * visual(Poly)
draw(plt; axis=(aspect=1,))

# ## New columns on the fly

# Use a `Tuple` to pass combine several columns into a unique operation.

df = (x=rand(100), y=rand(100), z=rand(100), c=rand(["a", "b"], 100))
layers = linear() + mapping(color=:z)
plt = data(df) * layers * mapping(:x, (:x, :y, :z) => (+) => "x + y + z", layout=:c)
draw(plt)

# ## Pre-grouped data

x = [rand(10) for i in 1:3]
y = [rand(10) for i in 1:3]
z = [rand(10) for i in 1:3]
c = ["a", "b", "c"]

m = mapping(x, y, color=c => (t -> "Type " * t ) => "Category")
draw(m)

#

m = mapping(x, (y, z) => (+) => "sum", color=c => (t -> "Type " * t ) => "Category")
draw(m)

#

m = mapping(x, [y z], color=dims(1) => renamer(["a", "b", "c"]))
draw(m)

#

m = mapping(x, [y z], color=["1" "2"])
layers = visual(Scatter) + linear()
draw(m * layers)

# ## Legend merging

N = 40

x = [1:N; 1:N]
y = [cumsum(randn(N)); cumsum(randn(N))]
grp = [fill("a", N); fill("b", N)]

df = (; x, y, grp)

layers = visual(Lines) + visual(Scatter) * mapping(marker = :grp)
plt = data(df) * layers * mapping(:x, :y, color = :grp)

draw(plt)

#
