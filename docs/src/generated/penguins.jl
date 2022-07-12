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

draw(penguin_frequency; axis)

# ### Small intermezzo: saving the plot
#
# If you are working in an interactive enviroment with inline plotting support,
# such VSCode or Pluto.jl, the above should have displayed a bar plot.
# If you are working directly in the console, you can simply save the plot and
# inspect it in the file explorer.
#
# ```julia
# fg = draw(penguin_frequency; axis)
# save("figure.png", fg, px_per_unit = 3) # save high-resolution png
# ```
#
# ### Styling by categorical variables
#
# Next, let us see whether the distribution is the same across islands.

plt = penguin_frequency * mapping(color = :island)
draw(plt; axis)

# Oops! The bars are in the same spot and are hiding each other. We need to specify
# how we want to fix this. Bars can either `dodge` each other, or be `stack`ed on top
# of each other.

plt = penguin_frequency * mapping(color = :island, dodge = :island)
draw(plt; axis)

# This is our first finding. `Adelie` is the only species of penguins that can be
# found on all three islands. To be able to see both which species is more numerous
# and how different species are distributed across islands in a unique plot, 
# we could have used `stack`.

plt = penguin_frequency * mapping(color = :island, stack = :island)
draw(plt; axis)

# ## Correlating two variables
#
# Now that we have understood the distribution of these three penguin species, we can
# start analyzing their features.

penguin_bill = data(penguins) * mapping(:bill_length_mm, :bill_depth_mm)
draw(penguin_bill; axis)

# We would actually prefer to visualize these measures in centimeters, and to have
# cleaner axes labels. As we want this setting to be preserved in all of our `bill`
# visualizations, let us save it in the variable `penguin_bill`, to be reused in
# subsequent plots.

penguin_bill = data(penguins) * mapping(
    :bill_length_mm => (t -> t / 10) => "bill length (cm)",
    :bill_depth_mm => (t -> t / 10) => "bill depth (cm)",
)
draw(penguin_bill; axis)

# Much better! Note the parentheses around the function `t -> t / 10`. They are
# necessary to specify that the function maps `t` to `t / 10`, and not to
# `t / 10 => "bill length (cm)"`.

# There does not seem to be a strong correlation between the two dimensions, which
# is odd. Maybe dividing the data by species will help.

plt = penguin_bill * mapping(color = :species)
draw(plt; axis)

# Ha! Within each species, penguins with a longer bill also have a deeper bill.
# We can confirm that with a linear regression

plt = penguin_bill * linear() * mapping(color = :species)
draw(plt; axis)

# This unfortunately no longer shows our data!
# We can use `+` to plot both things on top of each other:

plt = penguin_bill * linear() * mapping(color = :species) + penguin_bill * mapping(color = :species)
draw(plt; axis)

# Note that the above expression seems a bit redundant, as we wrote the same thing twice.
# We can "factor it out" as follows

plt = penguin_bill * (linear() + mapping()) * mapping(color = :species)
draw(plt; axis)

# where `mapping()` is a neutral multiplicative element.
# Of course, the above could be refactored as

layers = linear() + mapping()
plt = penguin_bill * layers * mapping(color = :species)
draw(plt; axis)

# We could actually take advantage of the spare `mapping()` and use it to pass some
# extra info to the scatter, while still using all the species members to compute
# the linear fit. 

layers = linear() + mapping(marker = :sex)
plt = penguin_bill * layers * mapping(color = :species)
draw(plt; axis)

# This plot is getting a little bit crowded. We could instead show female and
# male penguins in separate subplots.

layers = linear() + mapping(col = :sex)
plt = penguin_bill * layers * mapping(color = :species)
draw(plt; axis)

# See how both plots show the same fit, because the `sex` mapping is not applied
# to `linear()`. The following on the other hand produces a separate fit for
# males and females:

layers = linear() + mapping()
plt = penguin_bill * layers * mapping(color = :species, col = :sex)
draw(plt; axis)

# ## Smooth density plots
#
# An alternative approach to understanding how two variables interact is to consider
# their joint probability density distribution (pdf).

using AlgebraOfGraphics: density
plt = penguin_bill * density(npoints=50) * mapping(col = :species)
draw(plt; axis)

# The default colormap is multi-hue, but it is possible to pass single-hue colormaps as well.
# The color range is inferred from the data by default, but it can also be passed manually.

plt *= visual(colormap = :grayC, colorrange = (0, 6))
draw(plt; axis)

# A `Heatmap` (the default visualization for a 2D density) is a bit unfortunate if
# we want to mark species by color. In that case, one can use `visual` to change
# the default visualization and, optionally, fine tune some arguments.
# In this case, a `Wireframe` with thin lines looks quite nice. (Note that, for the
# time being, we must specify explicitly that we require a 3D axis.)

axis = (type = Axis3, width = 300, height = 300)
layer = density() * visual(Wireframe, linewidth=0.05)
plt = penguin_bill * layer * mapping(color = :species)
draw(plt; axis)

# Of course, a more traditional approach would be to use a `Contour` plot instead:

axis = (width = 225, height = 225)
layer = density() * visual(Contour)
plt = penguin_bill * layer * mapping(color = :species)
draw(plt; axis)

# The data and the linear fit can also be added back to the plot:

layers = density() * visual(Contour) + linear() + mapping()
plt = penguin_bill * layers * mapping(color = :species)
draw(plt; axis)

# In the case of many layers (contour, density and scatter) it is important to think
# about balance. In the above plot, the markers are quite heavy and can obscure the linear
# fit and the contour lines.
# We can lighten the markers using alpha transparency.

layers = density() * visual(Contour) + linear() + visual(alpha = 0.5)
plt = penguin_bill * layers * mapping(color = :species)
draw(plt; axis)

# ## Correlating three variables
#
# We are now mostly up to speed with `bill` size, but we have not considered how
# it relates to other penguin features, such as their weight.
# For that, a possible approach is to use a continuous color
# on a gradient to denote weight and different marker shapes to denote species.
# Here we use `group` to split the data for the linear regression without adding
# any additional style.

body_mass = :body_mass_g => (t -> t / 1000) => "body mass (kg)"
layers = linear() * mapping(group = :species) + mapping(color = body_mass, marker = :species)
plt = penguin_bill * layers
draw(plt; axis)

# Naturally, within each species, heavier penguins have bigger bills, but perhaps
# counter-intuitively the species with the shallowest bills features the heaviest penguins.
# We could also try and see the interplay of these three variables in a 3D plot.

axis = (type = Axis3, width = 300, height = 300)
plt = penguin_bill * mapping(body_mass, color = :species)
draw(plt; axis)

#

plt = penguin_bill * mapping(body_mass, color = :species, layout = :sex)
draw(plt; axis)

# Note that static 3D plot can be misleading, as they only show one projection
# of 3D data. They are mostly useful when shown interactively.
#
# ## Machine Learning
#
# Finally, let us use Machine Learning techniques to build an automated penguin classifier!
#
# We would like to investigate whether it is possible to predict the species of a penguin
# based on its bill size. To do so, we will use a standard classifier technique
# called [Support-Vector Machine](https://en.wikipedia.org/wiki/Support-vector_machine).
#
# The strategy is quite simple. We split the data into training and testing
# subdatasets. We then train our classifier on the training dataset and use it to
# make predictions on the whole data. We then add the new columns obtained this way
# to the dataset and visually inspect how well the classifier performed in both
# training and testing.

using LIBSVM, Random

## use approximately 80% of penguins for training
Random.seed!(1234) # for reproducibility
N = nrow(penguins)
train = fill(false, N)
perm = randperm(N)
train_idxs = perm[1:floor(Int, 0.8N)]
train[train_idxs] .= true
nothing # hide

## fit model on training data and make predictions on the whole dataset
X = hcat(penguins.bill_length_mm, penguins.bill_depth_mm)
y = penguins.species
model = SVC() # Support-Vector Machine Classifier
fit!(model, X[train, :], y[train])
ŷ = predict(model, X)

## incorporate relevant information in the dataset
penguins.train = train
penguins.predicted_species = ŷ
nothing #hide

# Now, we have all the columns we need to evaluate how well our classifier performed.

axis = (width = 225, height = 225)
dataset =:train => renamer(true => "training", false => "testing") => "Dataset"
accuracy = (:species, :predicted_species) => isequal => "accuracy"
plt = data(penguins) *
    expectation() *
    mapping(:species, accuracy) *
    mapping(col = dataset)
draw(plt; axis)

# That is a bit hard to read, as all values are very close to `1`.
# Let us visualize the error rate instead.

error_rate = (:species, :predicted_species) => !isequal => "error rate"
plt = data(penguins) *
    expectation() *
    mapping(:species, error_rate) *
    mapping(col = dataset)
draw(plt; axis)

# So, mostly our classifier is doing quite well, but there are some mistakes,
# especially among `Chinstrap` penguins. Using *at the same time* the `species` and
# `predicted_species` mappings on different attributes, we can see which penguins
# are problematic.

prediction = :predicted_species => "predicted species"
datalayer = mapping(color = prediction, row = :species, col = dataset)
plt = penguin_bill * datalayer
draw(plt; axis)

# Um, some of the penguins are indeed being misclassified... Let us try to understand why
# by adding an extra layer, which describes the density of the distributions of the three
# species.

pdflayer = density() * visual(Contour, colormap=Reverse(:grays)) * mapping(group = :species)
layers = pdflayer + datalayer
plt = penguin_bill * layers
draw(plt; axis)

# We can conclude that the classifier is doing a reasonable job:
# it is mostly making mistakes on outlier penguins.
