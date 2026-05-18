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

# Inner per-column workers — function barriers so the row-iteration hot loop
# specializes on the column's concrete type without forcing the outer filter
# to recompile for every positional-tuple shape.
function _accumulate_keep!(keep::BitVector, col::AbstractVector)
    length(keep) == length(col) || throw(DimensionMismatch("column length $(length(col)) does not match $(length(keep))"))
    @inbounds for i in eachindex(keep)
        keep[i] || continue
        keep[i] = !_should_drop_missing_nan(col[i])
    end
    return keep
end

function _check_no_inf(col::AbstractVector, what)
    n = count(_is_inf, col)
    n > 0 && throw(
        ArgumentError(
            "Encountered $n `Inf`/`-Inf` value(s) in $what; analyses do not support infinite values. Filter or transform these rows before passing the data."
        )
    )
    return nothing
end

function _filter_and_check(col::AbstractVector, keep::BitVector, what)
    filtered = col[keep]
    _check_no_inf(filtered, what)
    return _narrow_nonmissing(filtered)
end

# Drop rows where any column in `positional`, or any column in `named` indexed
# by `weight_keys`, contains `missing` or `NaN`. After dropping, throw on any
# remaining `Inf`/`-Inf` in positional or retained weight columns. Returns the
# filtered (positional, named), with `Union{Missing,T}` element types narrowed
# to `T`. `positional` is iterated as a generic collection of column vectors so
# this method does not recompile per positional-tuple shape; the per-column
# work is delegated to specialized inner helpers.
function _drop_missing_nan_rows(
        positional, named::AbstractDictionary;
        weight_keys = (:weights,),
    )
    isempty(positional) && return positional, named
    nrows = length(first(positional))
    keep = trues(nrows)
    for col in positional
        _accumulate_keep!(keep, col)
    end
    present_weight_keys = filter(k -> haskey(named, k), collect(weight_keys))
    for k in present_weight_keys
        _accumulate_keep!(keep, named[k])
    end

    new_positional = Any[
        _filter_and_check(col, keep, "positional column $idx")
            for (idx, col) in enumerate(positional)
    ]

    new_named = named
    for k in present_weight_keys
        new_named = set(new_named, k => _filter_and_check(named[k], keep, "`$(k)`"))
    end
    return new_positional, new_named
end
