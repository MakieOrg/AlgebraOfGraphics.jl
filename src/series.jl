# Combine different `AbstractTrace`s in a `Series` obect

# TODO: give richer structure, maybe a tree?
struct Series
    list::Vector{AbstractTrace}
end
Series(v::Vector) = Series(convert(Vector{AbstractTrace}, v))
Series(s::Series) = s
Series(t::AbstractTrace) = Series([t])

Base.iterate(s::Series) = iterate(s.list)
Base.iterate(s::Series, i) = iterate(s.list, i)
Base.length(s::Series) = length(s.list)
Base.eltype(::Type{Series}) = AbstractTrace

# TODO: also define a specialized map method?

function Base.show(io::IO, s::Series)
    print(io, "Series of length $(length(s))")
end

(t::Trace)(s::Series) = Series(map(t, s))
(s::Series)(t::AbstractTrace) = Series(map(f -> f(t), s))
(s::Series)(t::Series) = Series([ss(tt) for ss in s for tt in t])

function Base.:+(a::Union{AbstractTrace, Series}, b::Union{AbstractTrace, Series})
    a = Series(a)
    b = Series(b)
    return Series(vcat(a.list, b.list))
end

# ranking

jointable(ts) = jointable(ts, foldl(merge, ts))

function jointable(ts, ::NamedTuple{names}) where names
    vals = map(names) do name
        vcat((get(table, name, Union{}[]) for table in ts)...)
    end
    NamedTuple{names}(vals)
end

primarytable(t::AbstractTrace) = fieldarrays(StructArray(p for (p, _) in pairs(t)))
primarytable(series::Series) = jointable(map(primarytable, series))

rankdict(d) = Dict(val => i for (i, val) in enumerate(uniquesorted(vec(d))))

rankdicts(ts::Union{AbstractTrace, Series}) = map(rankdict, primarytable(ts))
