const Mean = let
    init() = (0, 0.0)
    op((n, sum), val) = n + 1, sum + val
    value((n, sum)) = sum / n
    (; init, op, value)
end

struct ExpectationAnalysis end

(e::ExpectationAnalysis)(input::ProcessedLayer) = groupreduce(Mean, input)

"""
    expectation()

Compute the expected value of the last argument conditioned on the preceding ones.

Rows with `missing` or `NaN` in any numeric input are dropped; `Inf`/`-Inf` errors.
"""
expectation() = transformation(ExpectationAnalysis())
