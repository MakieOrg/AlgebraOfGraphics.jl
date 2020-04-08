# immutable dict object that supports algebraic operations

struct AlgebraicDict{K, V, KS, VS} <: AbstractDict{K, V}
    dict::LittleDict{K, V, KS, VS}
end

AlgebraicDict(args...) = AlgebraicDict(LittleDict(args...))
function AlgebraicDict{K, V}(args...) where {K, V}
    l = LittleDict{K, V}(args...)
    return AlgebraicDict(l)
end
AlgebraicDict(a::AlgebraicDict) = a

getdict(d::AlgebraicDict) = d.dict

# immutable implementation

Base.length(dd::AlgebraicDict) = length(getdict(dd))

Base.getkey(dd::AlgebraicDict, key, default) = Base.getkey(getdict(dd), key, default)

Base.get(dd::AlgebraicDict, key, default) = get(getdict(dd), key, default)
Base.get(default::Base.Callable, dd::AlgebraicDict, key) = get(default, getdict(dd), key)

Base.iterate(dd::AlgebraicDict)    = iterate(getdict(dd))
Base.iterate(dd::AlgebraicDict, i) = iterate(getdict(dd), i)

function Base.merge(d1::AlgebraicDict, d2::AbstractDict)
    return merge((x,y)->y, d1, d2)
end

function Base.merge(combine::Function, d::AlgebraicDict, others::AbstractDict...)
    l = getdict(d)
    ll = merge(combine, l, others...)
    return AlgebraicDict(ll)
end

Base.empty(dd::AlgebraicDict{K,V}) where {K,V} = AlgebraicDict{K,V}()

# Algebraic operations

Base.:+(s1::AlgebraicDict, s2::AlgebraicDict) = merge(+, s1, s2)
function Base.:*(s1::AlgebraicDict, s2::AlgebraicDict)
    k = [merge(k1, k2) for k1 in keys(s1) for k2 in keys(s2)]
    v = [v1 * v2 for v1 in values(s1) for v2 in values(s2)]
    return AlgebraicDict(k, v)
end
