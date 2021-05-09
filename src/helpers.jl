struct Sorted{T}
    idx::UInt32
    value::T
end

Base.print(io::IO, s::Sorted) = print(io, s.value)
Base.isless(s1::Sorted, s2::Sorted) = isless((s1.idx, s1.value), (s2.idx, s2.value))

struct Renamer{U, L}
    uniquevalues::U
    labels::L
end

function renamer(p::Pair, ps::Pair...)
    pairs = (p, ps...)
    k, v = map(first, pairs), map(last, pairs)
    return Renamer(k, v)
end

function (r::Renamer)(x)
    i::UInt32 = findfirst(isequal(x), r.uniquevalues)
    label = r.labels[i]
    return Sorted(i, label)
end

struct NonNumeric{T}
    x::T
end

nonnumeric(x) = NonNumeric(x)

Base.print(io::IO, n::NonNumeric) = print(io, n.x)
Base.isless(n1::NonNumeric, n2::NonNumeric) = isless(n1.x, n2.x)
