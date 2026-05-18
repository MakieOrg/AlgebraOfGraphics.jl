const Mean = let
    init() = (0, 0.0)
    op((n, sum), val) = n + 1, sum + val
    value((n, sum)) = sum / n
    (; init, op, value)
end

struct ExpectationAnalysis end

function (e::ExpectationAnalysis)(input::ProcessedLayer)
    input = map(input) do p, n
        return _drop_missing_nan_rows(p, n)
    end
    return groupreduce(Mean, input)
end

"""
    expectation()

Compute the expected value of the last argument conditioned on the preceding ones.

Rows with `missing` or `NaN` in any numeric input are dropped; `Inf`/`-Inf` errors.
"""
expectation() = transformation(ExpectationAnalysis())
