using AlgebraOfGraphics, CairoMakie
using Statistics: mean, median, sum, extrema





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


