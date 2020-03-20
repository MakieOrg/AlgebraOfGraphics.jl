# Not tested!

using AbstractPlotting, GLMakie
using Observables
using AbstractPlotting: SceneLike, PlotFunc
using StatsMakie: linear, density

using AlgebraOfGraphics, Test
using AlgebraOfGraphics: Sum, AbstractSpec, table, data, metadata, primary, analysis, mixedtuple, rankdicts
using OrderedCollections

using RDatasets: dataset
using MakieLayout
using GLFW
GLFW.WindowHint(GLFW.FLOATING, 1)

isabstractplot(s) = isa(s, Type) && s <: AbstractPlot

function get_attrs(grp::NamedTuple{names}, user_options, palette, rks) where names
    tup = map(names) do key
        user = get(user_options, key, Observable(nothing))
        default = get(palette, key, Observable(nothing))
        scale = isa(user[], AbstractVector) ? user[] : default[]
        val = getproperty(grp, key)
        idx = rks[key][val]
        scale isa AbstractVector ? scale[mod1(idx, length(scale))] : idx
    end
    return merge(user_options, Attributes(NamedTuple{names}(tup)))
end

function layoutplot!(scene, l, s::Sum; kwargs...)
    attributes = Attributes(kwargs)
    ms = map(metadata, s)
    ods = map(OrderedDict, s)
    palette = AbstractPlotting.current_default_theme()[:palette]
    rks = rankdicts(map(collect∘keys, ods))
    axdict = Dict()
    for (od, m) in zip(ods, ms)
        P1 = foldl((a, b) -> isabstractplot(b) ? b : a, m.args, init=Any)
        args = Iterators.filter(!isabstractplot, m.args)
        series_attr = merge(attributes, Attributes(m.kwargs))
        for (key, val) in od
            attrs = get_attrs(key, series_attr, palette, rks)
            x_pos = pop!(attrs, :layout_x, Observable(1))[]
            y_pos = pop!(attrs, :layout_y, Observable(1))[]
            current = get!(axdict, (x_pos, y_pos)) do
                l[y_pos, x_pos] = LAxis(scene)
            end
            AbstractPlotting.plot!(current, P1, merge(attrs, Attributes(val.kwargs)), args..., val.args...)
        end
    end
    return scene
end
layoutplot(s::Sum) = layoutplot!(layoutscene(resolution = (2000, 2000))..., s)
layoutplot(s::AbstractSpec) = layoutplot!(layoutscene(resolution = (2000, 2000))..., Sum((s,)))

scene, layout = layoutscene(resolution = (2000, 2000))
scene

iris = dataset("datasets", "iris")
spec = data(:SepalLength, :SepalWidth)
grp = primary(layout_x = :Species)
geom = metadata(Scatter, markersize = 10px) + analysis(linear)
layoutplot(table(iris) * spec * geom * grp)

iris = dataset("datasets", "iris")
xcols = data(:SepalLength) * primary(layout_x = fill(1)) +
        data(:SepalWidth) * primary(layout_x = fill(2))
ycols = data(:PetalLength) * primary(layout_y = fill(1)) +
        data(:PetalWidth) * primary(layout_y = fill(2))
dataspec = table(iris) * xcols * ycols
sc = metadata(Scatter, markersize = 10px)
layoutplot(dataspec * sc)

linreg = analysis(linear) * metadata(linewidth = 5)
layoutplot(dataspec * (sc + linreg))

layoutplot(dataspec * (sc + linreg) * primary(color = :Species))
