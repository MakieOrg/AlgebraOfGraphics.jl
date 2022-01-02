const KeyType = Union{Symbol, Int}

const Arguments = Vector{Any}
const NamedArguments = Dictionary{Symbol, Any}
const MixedArguments = Dictionary{KeyType, Any}

# make a copy with distinct keys
function set(d::AbstractDictionary, ps::Pair...)
    res = similar(copy(keys(d)), eltype(d))
    copyto!(res, d)
    for (k, v) in ps
        set!(res, k, v)
    end
    return res
end

function unset(d::AbstractDictionary, ks...)
    idxs = findall(!in(ks), keys(d))
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

function valid_options(nt)
    ks = filter(k -> nt[k] !== automatic, keys(nt))
    return NamedTuple{ks}(nt)
end