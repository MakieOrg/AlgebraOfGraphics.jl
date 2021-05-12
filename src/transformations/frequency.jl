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
    N = length(getvalue(entry.positional[1]))
    augmented = (entry.positional..., Labeled("count", fill(nothing, N)))
    named, attributes = entry.named, entry.attributes
    return groupreduce(Counter, Entry(plottype, augmented, named, attributes))
end

"""
    frequency()

Compute a frequency table of the arguments.
"""
frequency() = Layer((FrequencyAnalysis(Dict{Symbol, Any}()),))
