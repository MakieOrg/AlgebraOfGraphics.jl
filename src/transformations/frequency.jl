const Counter = let
    init() = 0
    op(n, _) = n + 1
    value(n) = n
    (; init, op, value)
end

struct FrequencyAnalysis
    options::Dict{Symbol, Any}
end

function (f::FrequencyAnalysis)(entry::Entry)
    plottype = entry.plottype
    mappings = copy(entry.mappings)
    N = length(getvalue(mappings[1]))
    push!(mappings.positional, Labeled("count", fill(nothing, N)))
    attributes = entry.attributes
    return groupreduce(Counter, Entry(plottype, mappings, attributes))
end

"""
    frequency()

Compute a frequency table of the arguments.
"""
frequency() = Layer((FrequencyAnalysis(Dict{Symbol, Any}()),))
