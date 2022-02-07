const KeyType = Union{Symbol, Int}

const Arguments = Vector{Any}
const NamedArguments = Dictionary{Symbol, Any}
const MixedArguments = Dictionary{KeyType, Any}

# make a copy with distinct keys
set(d::AbstractDictionary, ps::Pair...) = merge(d, Dictionary(map(first, ps), map(last, ps)))

function filterkeys(f, d::AbstractDictionary)
    idxs = findall(f, keys(d))
    return getindices(d, idxs)
end

function separate(f, d::AbstractDictionary)
    d1, d2 = empty(d), empty(d)
    for (k, v) in pairs(d)
        target = ifelse(f(v), d1, d2)
        insert!(target, k, v)
    end
    return d1, d2
end

valid_options(; options...) = valid_options(values(options))

function valid_options(nt)
    ks = filter(k -> nt[k] !== automatic, keys(nt))
    return NamedTuple{ks}(nt)
end
