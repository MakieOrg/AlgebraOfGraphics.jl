const Counter = let
    init() = 0
    op(n, _) = n + 1
    value(n) = n
    (; init, op, value)
end

struct FrequencyAnalysis end

to_nothings(v) = fill(nothing, axes(v))

function (f::FrequencyAnalysis)(input::ProcessedLayer)
    positional = vcat(input.positional, Any[map(to_nothings, first(input.positional))])
    labels = set(input.labels, length(positional) => "count")
    augmented_input = ProcessedLayer(input; positional, labels)
    return groupreduce(Counter, augmented_input)
end

"""
    frequency()

Compute a frequency table of the arguments.
"""
frequency() = transformation(FrequencyAnalysis())
