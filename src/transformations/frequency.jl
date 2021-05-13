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
    plottype, primary, positional, named, labels =
        entry.plottype, entry.primary, entry.positional, entry.named, copy(entry.labels)
    labels[length(positional) + 1] = "count"
    N = length(positional[1])
    augmented_entry =Entry(
        plottype,
        primary,
        (positional..., fill(nothing, N)),
        named,
        labels;
        entry.attributes...
    )
    return groupreduce(Counter, augmented_entry)
end

"""
    frequency()

Compute a frequency table of the arguments.
"""
frequency() = Layer((FrequencyAnalysis(Dict{Symbol, Any}()),))
