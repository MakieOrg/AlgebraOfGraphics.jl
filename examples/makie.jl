using AbstractPlotting, GLMakie
using StatsMakie: linear

using AlgebraOfGraphics, Test
using AlgebraOfGraphics: Sum, AbstractSpec, table, data, metadata, primary, analysis, mixedtuple, rankdicts
using OrderedCollections

using RDatasets: dataset

makieplot!(scn::Scene, s::AbstractSpec) = makieplot!(scn, Sum(s))

function makieplot!(scn::Scene, s::Sum)
    ms = map(metadata, s)
    ods = map(OrderedDict, s)
    palette = AbstractPlotting.current_default_theme()[:palette]
    rks = rankdicts(map(keys, ods))
    for (od, m) in zip(ods, ms)
        for (key, val) in od
            attrs = get_attrs(key, m.kwargs, palette, rks)
            plot!(scn, m.args..., val.args...; val.kwargs..., merge(m.kwargs, attrs)...)
        end
    end
    return scn
end

function get_attrs(grp::NamedTuple{names}, user_options, palette, rks) where names
    tup = map(names) do key
        user = get(user_options, key, nothing)
        scale = isa(user, AbstractVector) ? user : palette[key][]
        val = getproperty(grp, key)
        return scale[mod1(rks[key][val], length(scale))]
    end
    NamedTuple{names}(tup)
end

makieplot(s) = makieplot!(Scene(), s)

#######

iris = dataset("datasets", "iris")
spec = table(iris) * data(:PetalLength, :PetalWidth) * primary(color = :Species)
s = metadata(Scatter, markersize = 10px) + analysis(linear)
makieplot(s * spec)


x = [-pi..0, 0..pi]
y = [sin, cos]
ts1 = sum(((i, el),) -> primary(color = i) * data(el), enumerate(x))
ts2 = sum(((i, el),) -> primary(linestyle = i) * data(el), enumerate(y))
makieplot(ts1 * ts2 * metadata(linewidth = 10))
