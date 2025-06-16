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
"""
expectation() = transformation(ExpectationAnalysis())
