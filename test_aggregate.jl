using AlgebraOfGraphics, CairoMakie
using Statistics: mean





## Mean of x over y values

# Create test data with multiple y values for each x
y_vals = repeat([1, 2, 3, 4, 5], inner=10)
x_vals = y_vals .* 2 .+ randn(50) .* 0.5  # Linear relationship with noise

data_df = (; y=y_vals, x=x_vals)

# Create layers: raw data + aggregated mean
layer_raw = data(data_df) * mapping(:x, :y) * visual(Scatter, color=(:gray, 0.3))
layer_mean = data(data_df) * mapping(:x, :y) * aggregate(mean, :) * visual(Lines, color=:red, linewidth=3)

plt = layer_raw + layer_mean
fig = draw(plt)




## Mean with color mapping aggregation

using Statistics: median

# Create test data with DIFFERENT group sizes
x_vals = vcat(
    fill(1, 5),   # 5 points
    fill(2, 10),  # 10 points
    fill(3, 15),  # 15 points
    fill(4, 8),   # 8 points
    fill(5, 12),  # 12 points
)
y_vals = x_vals .* 2 .+ randn(length(x_vals)) .* 0.5  # Linear relationship with noise
color_vals = randn(length(x_vals)) .+ x_vals  # Color values correlated with x

data_df = (; x=x_vals, y=y_vals, color=color_vals)

# Create layers: raw data (gray) + aggregated mean with group size color
layer_raw = data(data_df) * mapping(:x, :y) * visual(Scatter, alpha=0.3, color=:gray)
layer_agg = data(data_df) * mapping(:x, :y, color=:color) * 
    aggregate(:, mean, color = length) * 
    visual(Scatter, markersize=20, marker=:diamond, colormap=:viridis)

plt = layer_raw + layer_agg
fig = draw(plt)




## Test with missing values - mean should return missing for groups with missing

# Create test data where one group has a missing value
x_vals = repeat([1, 2, 3, 4, 5], inner=10)
y_vals = x_vals .* 2 .+ randn(50) .* 0.5  # Linear relationship with noise

# Add a missing value to the second group (x=2)
y_vals_with_missing = Vector{Union{Float64, Missing}}(y_vals)
y_vals_with_missing[15] = missing  # One value in x=2 group

data_df = (; x=x_vals, y=y_vals_with_missing)

# Create layers: raw data + aggregated mean
layer_raw = data(data_df) * mapping(:x, :y) * visual(Scatter, color=(:gray, 0.3))
layer_mean = data(data_df) * mapping(:x, :y) * aggregate(:, mean) * visual(Scatter, color=:blue, markersize=20)

plt = layer_raw + layer_mean
fig = draw(plt)




## Heatmap by grouping over x and y, aggregating z with sum

using Statistics: sum

# Create test data with multiple z values for each x,y combination
# Random points scattered in a 5x5 grid
n_points = 50
x_vals = rand(1:5, n_points)
y_vals = rand(1:5, n_points)
z_vals = randn(n_points) .+ 10  # Random values around 10

data_df = (; x=x_vals, y=y_vals, z=z_vals)

# Create heatmap using aggregate with two grouping dimensions
layer_heatmap = data(data_df) * mapping(:x, :y, :z) * 
    aggregate(:, :, sum) * 
    visual(Heatmap)

fig = draw(layer_heatmap)




## Range bars using extrema split into min and max

using Statistics: extrema

# Create test data with multiple y values for each x (varying spread)
x_vals = repeat([1, 2, 3, 4, 5], inner=10)
y_vals = x_vals .* 2 .+ randn(50) .* (0.5 .+ x_vals .* 0.2)  # Increasing variance

data_df = (; x=x_vals, y=y_vals)

# Create layers: raw data + range bars showing min/max
layer_raw = data(data_df) * mapping(:x, :y) * visual(Scatter, alpha=0.3, color=:gray)
layer_range = data(data_df) * mapping(:x, :y) * 
    aggregate(:, extrema => [first => 2, last => 3]) * 
    visual(Rangebars, color=:red, linewidth=3)

plt = layer_raw + layer_range
fig = draw(plt)




## Heatmap with custom label


# Create test data with multiple z values for each x,y combination
n_points = 50
x_vals = rand(1:5, n_points)
y_vals = rand(1:5, n_points)
z_vals = randn(n_points) .+ 10  # Random values around 10

data_df = (; x=x_vals, y=y_vals, z=z_vals)

# Create heatmap using aggregate with custom label "Total"
layer_heatmap = data(data_df) * mapping(:x, :y, :z) * 
    aggregate(:, :, sum => rich("total ", rich("of z", font = :bold)) => scale(:color2)) * 
    visual(Heatmap)

fig = draw(layer_heatmap, scales(color2 = (; colormap = :Blues)))




## Split extrema with separate labels and custom scale for upper bound

using Statistics: extrema

# Create test data with multiple y values for each x (varying spread)
x_vals = repeat([1, 2, 3, 4, 5], inner=10)
y_vals = x_vals .* 2 .+ randn(50) .* (0.5 .+ x_vals .* 0.2)  # Increasing variance

data_df = (; x=x_vals, y=y_vals)

# Split extrema: lower bound becomes y position, upper bound becomes color with custom scale
layer_scatter = data(data_df) * mapping(:x, :y) * 
    aggregate(:, extrema => [
        first => 2 => "Min",  # Lower bound as y coordinate with label "Min"
        last => :color => "Max" => scale(:color2)  # Upper bound as color with label "Max" and custom scale
    ]) * 
    visual(Scatter, markersize=25)

fig = draw(layer_scatter, scales(color2 = (; colormap = :thermal)))


