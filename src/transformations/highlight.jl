struct Highlight{F<:Function}
    target::Vector{Union{Int,Symbol}}
    predicate::F
    repeat_facets::Bool
end

function Highlight(
    target::Vector,
    predicate;
    repeat_facets = false
)
    return Highlight(
        convert(Vector{Union{Int,Symbol}}, target),
        predicate,
        repeat_facets
    )
end

function (highlight::Highlight)(p::ProcessedLayer)
    primary = AlgebraOfGraphics.dictionary([(key == :color ? :group : key, value) for (key, value) in pairs(p.primary)
        # should the data be repeated across all facets or not? maybe needs to be an option
        if !(highlight.repeat_facets && key in (:layout, :row, :col))
    ])
    
    grayed_out = ProcessedLayer(p; primary, attributes = merge(p.attributes, AlgebraOfGraphics.dictionary([:color => :gray80])))

    function apply_predicate(target::Vector, predicate::Function, positional, named, scalar_primaries)
        b = predicate([resolve_target(t, positional, named, scalar_primaries) for t in target]...)
        b isa Bool || error("Highlighting predicate returned non-boolean value $b")
        return b
    end
    
    resolve_target(target::Int, positional, named, scalar_primaries) = positional[target]
    resolve_target(target::Symbol, positional, named, scalar_primaries) = haskey(scalar_primaries, target) ? scalar_primaries[target] : named[target]


    i::Int = 0
    colored = AlgebraOfGraphics.filtermap(p) do positional, named
        i += 1
        scalar_primaries = map(val -> val[i], p.primary)
        if apply_predicate(highlight.target, highlight.predicate, positional, named, scalar_primaries)
            return positional, named
        else
            return nothing
        end
    end

    return ProcessedLayers([grayed_out, colored])
end

highlight(pair::Pair; kwargs...) = AlgebraOfGraphics.transformation(Highlight(vcat(pair[1]), pair[2]; kwargs...))