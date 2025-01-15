# # Tutorial 🐧

# This is a gentle and lighthearted tutorial on how to use tools from AlgebraOfGraphics,
# using as example dataset a collection of measurements on penguins[^1]. See 
# the [Palmer penguins website](https://allisonhorst.github.io/palmerpenguins/index.html)
# for more information.
#
# [^1]: Gorman KB, Williams TD, Fraser WR (2014) Ecological Sexual Dimorphism and Environmental Variability within a Community of Antarctic Penguins (Genus Pygoscelis). PLoS ONE 9(3): e90081. [DOI](https://doi.org/10.1371/journal.pone.0090081)

# To follow along this tutorial, you will need to install a few packages.
# All the required packages can be installed with the following command.
#
# ```julia
# julia> import Pkg; Pkg.add(["AlgebraOfGraphics", "CairoMakie", "DataFrames", "LIBSVM", "PalmerPenguins"])
# ```
#
# After the above command completes, we are ready to go.

using PalmerPenguins, DataFrames

penguins = dropmissing(DataFrame(PalmerPenguins.load()))
first(penguins, 6)

# ## Frequency plots
#
# Let us start by getting a rough idea of how the data is distributed.
#
# !!! note
#     Due to julia's compilation model, the first plot may take a while to appear.

using AlgebraOfGraphics, CairoMakie
set_aog_theme!()

axis = (width = 225, height = 225)
penguin_frequency = data(penguins) * frequency() * mapping(:species)

draw(penguin_frequency; axis = axis)

# ### Small intermezzo: saving the plot
#
# If you are working in an interactive enviroment with inline plotting support,
# such VSCode or Pluto.jl, the above should have displayed a bar plot.
# If you are working directly in the console, you can simply save the plot and
# inspect it in the file explorer.
#
# ```julia
# fg = draw(penguin_frequency; axis = axis)
# save("figure.png", fg, px_per_unit = 3) # save high-resolution png
# ```
#
# ### Styling by categorical variables
#
# Next, let us see whether the distribution is the same across islands.

plt = penguin_frequency * mapping(color = :island)
draw(plt; axis = axis)

# Oops! The bars are in the same spot and are hiding each other. We need to specify
# how we want to fix this. Bars can either `dodge` each other, or be `stack`ed on top
# of each other.

plt = penguin_frequency * mapping(color = :island, dodge = :island)
draw(plt; axis = axis)

# This is our first finding. `Adelie` is the only species of penguins that can be
# found on all three islands. To be able to see both which species is more numerous
# and how different species are distributed across islands in a unique plot, 
# we could have used `stack`.

plt = penguin_frequency * mapping(color = :island, stack = :island)
draw(plt; axis = axis)

# ## Correlating two variables
#
# Now that we have understood the distribution of these three penguin species, we can
# start analyzing their features.

penguin_bill = data(penguins) * mapping(:bill_length_mm, :bill_depth_mm)
draw(penguin_bill; axis = axis)

# We would actually prefer to visualize these measures in centimeters, and to have
# cleaner axes labels. As we want this setting to be preserved in all of our `bill`
# visualizations, let us save it in the variable `penguin_bill`, to be reused in
# subsequent plots.

penguin_bill = data(penguins) * mapping(
    :bill_length_mm => (t -> t / 10) => "bill length (cm)",
    :bill_depth_mm => (t -> t / 10) => "bill depth (cm)",
)
draw(penguin_bill; axis = axis)

# Much better! Note the parentheses around the function `t -> t / 10`. They are
# necessary to specify that the function maps `t` to `t / 10`, and not to
# `t / 10 => "bill length (cm)"`.

# There does not seem to be a strong correlation between the two dimensions, which
# is odd. Maybe dividing the data by species will help.

plt = penguin_bill * mapping(color = :species)
draw(plt; axis = axis)

