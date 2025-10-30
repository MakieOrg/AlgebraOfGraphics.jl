using AlgebraOfGraphics, CairoMakie
using Statistics: mean


## Simple mean of y over x values

# Create test data with multiple y values for each x
x_vals = repeat([1, 2, 3, 4, 5], inner=10)
y_vals = x_vals .* 2 .+ randn(50) .* 0.5  # Linear relationship with noise

data_df = (; x=x_vals, y=y_vals)

# Show what the means should be
println("Expected means for each x:")
for x in unique(x_vals)
    y_for_x = y_vals[x_vals .== x]
    println("x=$x: mean(y) = $(mean(y_for_x))")
end

# Create layers: raw data + aggregated mean
layer_raw = data(data_df) * mapping(:x, :y) * visual(Scatter, color=(:gray, 0.3))
layer_mean = data(data_df) * mapping(:x, :y) * aggregate(2 => mean, groupby=1) * visual(Lines, color=:red, linewidth=3)

plt = layer_raw + layer_mean
fig = draw(plt)

## Mean of x over y values

# Create test data with multiple y values for each x
y_vals = repeat([1, 2, 3, 4, 5], inner=10)
x_vals = y_vals .* 2 .+ randn(50) .* 0.5  # Linear relationship with noise

data_df = (; y=y_vals, x=x_vals)

# Show what the means should be
println("Expected means for each y:")
for y in unique(y_vals)
    y_for_x = x_vals[y_vals .== y]
    println("y=$y: mean(x) = $(mean(y_for_x))")
end

# Create layers: raw data + aggregated mean
layer_raw = data(data_df) * mapping(:x, :y) * visual(Scatter, color=(:gray, 0.3))
layer_mean = data(data_df) * mapping(:x, :y) * aggregate(1 => mean, groupby=2) * visual(Lines, color=:red, linewidth=3)

plt = layer_raw + layer_mean
fig = draw(plt)

## Mean with color mapping aggregation

using Statistics: median

# Create test data with color values
x_vals = repeat([1, 2, 3, 4, 5], inner=10)
y_vals = x_vals .* 2 .+ randn(50) .* 0.5  # Linear relationship with noise
color_vals = randn(50) .+ x_vals  # Color values correlated with x

data_df = (; x=x_vals, y=y_vals, color=color_vals)

# Show what the aggregations should be
println("\nExpected aggregations for each x:")
for x in unique(x_vals)
    mask = x_vals .== x
    println("x=$x: mean(y) = $(mean(y_vals[mask])), median(color) = $(median(color_vals[mask]))")
end

# Create layers: raw data + aggregated mean and median
layer_raw = data(data_df) * mapping(:x, :y, color=:color) * visual(Scatter, alpha=0.3)
layer_agg = data(data_df) * mapping(:x, :y, color=:color) * 
    aggregate(2 => mean, :color => median, groupby=1) * 
    visual(Scatter, markersize=20, marker=:diamond, colormap=:viridis)

plt = layer_raw + layer_agg
fig = draw(plt)

