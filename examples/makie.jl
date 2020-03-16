using AbstractPlotting, GLMakie
using StatsMakie: linear

using AlgebraOfGraphics, Test
using AlgebraOfGraphics: Sum, AbstractSpec, table, data, metadata, primary, analysis, mixedtuple, rankdicts
using OrderedCollections

using RDatasets: dataset

function makieplot!(scn::Scene, s::Sum)
    foreach(el -> makieplot!(scn, el), s)
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

function makieplot!(scn::Scene, s::AbstractSpec)
    m = metadata(s)
    o = OrderedDict(s)
    palette = AbstractPlotting.current_default_theme()[:palette]
    rks = rankdicts(keys(o))
    for (key, val) in o
        attrs = get_attrs(key, m.kwargs, palette, rks)
        plot!(scn, m.args..., val.args...; val.kwargs..., merge(m.kwargs, attrs)...)
    end
    return scn
end

makieplot(s) = makieplot!(Scene(), s)

iris = dataset("datasets", "iris")
spec = table(iris) * data(:PetalLength, :PetalWidth) * primary(color = :Species)
s = metadata(Scatter, markersize = 10px) + analysis(linear)
makieplot(s * spec)


