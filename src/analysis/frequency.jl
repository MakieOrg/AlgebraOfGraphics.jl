function _frequency(args...)
    data = fill(nothing, length(first(args)))
    return _reducer(args..., data; agg=Counter(Any), default=0)
end

"""
    frequency(data...)

Compute a frequency table of the arguments.
"""
const frequency = Analysis(_frequency)
