const Counter = let
    init() = 0
    op(n, _) = n + 1
    value(n) = n
    (; init, op, value)
end

struct FrequencyAnalysis
    options::Dict{Symbol, Any}
end

to_nothings(v) = fill(nothing, axes(v))

function (f::FrequencyAnalysis)(entry::Entry)
    positional = (entry.positional..., map(to_nothings, first(entry.positional)))
    labels = copy(entry.labels)
    labels[length(positional)] = "count"
    augmented_entry = Entry(entry; positional, labels)
    return groupreduce(Counter, augmented_entry)
end

"""
    frequency()

Compute a frequency table of the arguments.
"""
frequency() = Layer((FrequencyAnalysis(Dict{Symbol, Any}()),))
