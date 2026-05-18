# Helpers shared by analyses to drop rows with `missing` or `NaN` inputs.
# `Inf`/`-Inf` are not dropped; they error explicitly so callers see the issue
# instead of getting downstream "bandwidth must be positive" / "start and stop
# must be finite" errors or silent nonsense.

_should_drop_missing_nan(v) = ismissing(v) || (v isa Number && isnan(v))
_is_inf(v) = v isa Number && isinf(v)

function _narrow_nonmissing(v::AbstractVector)
    T = Base.nonmissingtype(eltype(v))
    T === eltype(v) && return v
    return Vector{T}(v)
end

function _check_no_inf(col, what)
    n = count(_is_inf, col)
    n > 0 && throw(
        ArgumentError(
            "Encountered $n `Inf`/`-Inf` value(s) in $what; analyses do not support infinite values. Filter or transform these rows before passing the data."
        )
    )
    return nothing
end

# Drop rows where any column in `positional`, or any column in `named` indexed
# by `weight_keys`, contains `missing` or `NaN`. After dropping, throw on any
# remaining `Inf`/`-Inf` in positional or retained weight columns. Returns the
# filtered (positional, named), with `Union{Missing,T}` element types narrowed
# to `T`.
function _drop_missing_nan_rows(
        positional::Tuple, named::AbstractDictionary;
        weight_keys = (:weights,),
    )
    isempty(positional) && return positional, named
    nrows = length(first(positional))
    keep = trues(nrows)
    for col in positional
        length(col) == nrows || throw(DimensionMismatch("positional columns have inconsistent lengths"))
        for i in 1:nrows
            keep[i] || continue
            keep[i] = !_should_drop_missing_nan(col[i])
        end
    end
    present_weight_keys = filter(k -> haskey(named, k), collect(weight_keys))
    for k in present_weight_keys
        w = named[k]
        length(w) == nrows || throw(DimensionMismatch("named column `$(k)` length $(length(w)) does not match positional length $nrows"))
        for i in 1:nrows
            keep[i] || continue
            keep[i] = !_should_drop_missing_nan(w[i])
        end
    end

    new_positional = map(c -> _narrow_nonmissing(c[keep]), positional)
    for (idx, col) in enumerate(new_positional)
        _check_no_inf(col, "positional column $idx")
    end

    new_named = named
    for k in present_weight_keys
        wfilt = named[k][keep]
        _check_no_inf(wfilt, "`$(k)`")
        new_named = set(new_named, k => _narrow_nonmissing(wfilt))
    end
    return new_positional, new_named
end
