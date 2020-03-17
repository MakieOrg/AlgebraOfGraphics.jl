using AbstractPlotting, GLMakie
using Observables
using AbstractPlotting: SceneLike, PlotFunc
using StatsMakie: linear, density

using AlgebraOfGraphics, Test
using AlgebraOfGraphics: Sum, AbstractSpec, table, data, metadata, primary, analysis, mixedtuple, rankdicts, Constant
using OrderedCollections

using RDatasets: dataset

function AbstractPlotting.plot!(scn::SceneLike, P::PlotFunc, attr:: Attributes, s::AbstractSpec)
    return AbstractPlotting.plot!(scn, P, attr, Sum((s,)))
end

isabstractplot(s) = isa(s, Type) && s <: AbstractPlot

function AbstractPlotting.plot!(scn::SceneLike, P::PlotFunc, attributes::Attributes, s::Sum)
    ms = map(metadata, s)
    ods = map(OrderedDict, s)
    palette = AbstractPlotting.current_default_theme()[:palette]
    rks = rankdicts(map(keys, ods))
    for (od, m) in zip(ods, ms)
        P1 = foldl((a, b) -> isabstractplot(b) ? b : a, m.args, init=P)
        args = Iterators.filter(!isabstractplot, m.args)
        series_attr = merge(attributes, Attributes(m.kwargs))
        for (key, val) in od
            attrs = get_attrs(key, series_attr, palette, rks)
            AbstractPlotting.plot!(scn, P1, merge(attrs, Attributes(val.kwargs)), args..., val.args...)
        end
    end
    return scn
end

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

#######

iris = dataset("datasets", "iris")
spec = table(iris) * data(:SepalLength, :SepalWidth) * primary(color = :Species)
s = metadata(Scatter, markersize = 10px) + analysis(linear)
plot(s * spec)

plt = plot(metadata(Wireframe) * spec * analysis(density))
scatter!(plt, spec)

df = table(iris)
x = data(:PetalLength) * primary(marker = Constant(1)) +
    data(:PetalWidth) * primary(marker = Constant(2))
y = data(:SepalLength, color = :SepalWidth)
plot(metadata(Scatter) * df * x * y)

x = [-pi..0, 0..pi]
y = [sin, cos]
ts1 = sum(((i, el),) -> primary(color = i) * data(el), enumerate(x))
ts2 = sum(((i, el),) -> primary(linestyle = i) * data(el), enumerate(y))
plot(ts1 * ts2 * metadata(linewidth = 10))
