struct Analysis{F} <: AbstractElement
    f::F
    kwargs::NamedTuple
end

Analysis(f; kwargs...) = Analysis(f, values(kwargs))

Spec(a::Analysis) = Spec((a,))

(a::Analysis)(; kwargs...) = Analysis(a.f, merge(a.kwargs, values(kwargs)))

(a::Analysis)(args...; kwargs...) = a.f(args...; merge(a.kwargs, values(kwargs))...)

# default fallback
function (a::Analysis)(d::AlgebraicDict{<:Spec})
    acc = AlgebraicDict()
    for (sp, val) in d
        for (p, st) in val
            pre = AlgebraicDict(sp => AlgebraicDict(p => style()))
            args, kwargs = split(st.value)
            acc += pre * a(args...; kwargs...)
        end
    end
    return acc
end

function computeanalysis(ad::AlgebraicDict, i=1)
    mapfoldl(+, pairs(ad), init=AlgebraicDict()) do (key, val)
        p = AlgebraicDict(key => val)
        ans = key.analysis
        length(ans) < i ? p : computeanalysis(ans[i](p), i + 1)
    end
end
