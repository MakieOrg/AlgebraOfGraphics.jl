# # Analyses
#
# ## Histogram
#
# ```@docs
# histogram
# ```

using AlgebraOfGraphics, CairoMakie
set_aog_theme!()

df = (x=randn(1000), y=randn(1000), z=rand(["a", "b", "c"], 1000))
specs = data(df) * mapping(:x, layout=:z) * histogram(bins=range(-2, 2, length=15))
draw(specs)

#

specs = data(df) * mapping(:x, dodge=:z, color=:z) * histogram(bins=range(-2, 2, length=15))
draw(specs)

#

specs = data(df) * mapping(:x, stack=:z, color=:z) * histogram(bins=range(-2, 2, length=15))
draw(specs)

#

data(df) * mapping(:x, :y, layout=:z) * histogram(bins=15) |> draw

# ## Density
#
# ```@docs
# AlgebraOfGraphics.density
# ```

df = (x=randn(5000), y=randn(5000), z=rand(["a", "b", "c", "d"], 5000))
datalimits = ((-2.5, 2.5),)
xz = data(df) * mapping(:x, layout=:z) * AlgebraOfGraphics.density(; datalimits)
axis = (; ylabel="")
draw(xz; axis)

#

data(df) * mapping(:x, :y, layout=:z) * AlgebraOfGraphics.density(npoints=50) |> draw

#

specs = data(df) * mapping(:x, :y, layout=:z) *
    AlgebraOfGraphics.density(npoints=50) * visual(Surface)
    
draw(specs, axis=(type=Axis3, zticks=0:0.1:0.2, limits=(nothing, nothing, (0, 0.2))))

# ## Frequency
#
# ```@docs
# frequency
# ```

df = (x=rand(["a", "b", "c"], 100), y=rand(["a", "b", "c"], 100), z=rand(["a", "b", "c"], 100))
specs = data(df) * mapping(:x, layout=:z) * frequency()
draw(specs)

#

specs = data(df) * mapping(:x, layout=:z, color=:y, stack=:y) * frequency()
draw(specs)

#

specs = data(df) * mapping(:x, :y, layout=:z) * frequency()
draw(specs)

# ## Expectation
#
# ```@docs
# expectation
# ```

df = (x=rand(["a", "b", "c"], 100), y=rand(["a", "b", "c"], 100), z=rand(100), c=rand(["a", "b", "c"], 100))
specs = data(df) * mapping(:x, :z, layout=:c) * expectation()
draw(specs)

#

specs = data(df) * mapping(:x, :z, layout=:c, color=:y, dodge=:y) * expectation()
draw(specs)

#

specs = data(df) * mapping(:x, :y, :z, layout=:c) * expectation()
draw(specs)

# ## Linear
#
# ```@docs
# linear
# ```

x = 1:0.05:10
a = rand(1:7, length(x))
y = 1.2 .* x .+ a .+ 0.5 .* randn.()
df = (; x, y, a)
specs = data(df) * mapping(:x, :y, color=:a => nonnumeric) * (linear() + visual(Scatter))
draw(specs)

# ## Smoothing
#
# ```@docs
# smooth
# ```

x = 1:0.05:10
a = rand(1:7, length(x))
y = sin.(x) .+ a .+ 0.1 .* randn.()
df = (; x, y, a)
specs = data(df) * mapping(:x, :y, color=:a => nonnumeric) * (smooth() + visual(Scatter))
draw(specs)
