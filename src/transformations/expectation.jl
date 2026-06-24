const Mean = let
    init() = (0, 0.0)
    op((n, sum), val) = n + 1, sum + val
    value((n, sum)) = sum / n
    (; init, op, value)
end

struct ExpectationAnalysis end

function (e::ExpectationAnalysis)(input::ProcessedLayer)
    # Strip units from the value column before reducing; the Mean aggregator's
    # `(0, 0.0)` init isn't dimensionally compatible with unit-bearing values.
    # Units are reapplied to the per-group means afterwards.
    N = length(input.positional)
    plottype = Makie.plottype(input.plottype, categoricalplottypes[N - 1])
    t = position_transform(input.axis_transforms, plottype, input.attributes, N, N)
    y_originals = last(input.positional)
    input_filtered = map(input) do p, n
        return _drop_missing_nan_rows(p, n)
    end
    positional_stripped = copy(input_filtered.positional)
    positional_stripped[end] = to_transformed_nested(t, positional_stripped[end])
    input_stripped = ProcessedLayer(input_filtered; positional = positional_stripped)

    reduced = groupreduce(Mean, input_stripped)
    positional = copy(reduced.positional)
    positional[end] = map(positional[end], y_originals) do m, y_orig
        from_transformed_numerical(m, y_orig, t)
    end
    return tag_scale_aesthetics(ProcessedLayer(reduced; positional), !isempty(input.axis_transforms))
end

"""
    expectation()

Compute the expected value of the last argument conditioned on the preceding ones.

Rows with `missing` or `NaN` in any numeric input are dropped; `Inf`/`-Inf` errors.
"""
expectation() = transformation(ExpectationAnalysis())
