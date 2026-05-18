# Helpers shared by analyses to drop rows with `missing` or `NaN` inputs.
# `Inf`/`-Inf` are not dropped; they error explicitly so callers see the issue
# instead of getting downstream "bandwidth must be positive" / "start and stop
# must be finite" errors or silent nonsense.

_is_missing_or_nan(v) = ismissing(v) || (v isa AbstractFloat && isnan(v))
_is_inf(v) = v isa AbstractFloat && isinf(v)

function _narrow_nonmissing(v::AbstractVector)
    T = Base.nonmissingtype(eltype(v))
    T === eltype(v) && return v
    return Vector{T}(v)
end

# Inner per-column workers — function barriers so the row-iteration hot loop
# specializes on the column's concrete type without forcing the outer filter
# to recompile for every positional-tuple shape.
function _accumulate_keep!(keep::BitVector, col::AbstractVector)
    iscontinuous(col) || return keep
    keep .&= .!_is_missing_or_nan.(col)
    return keep
end

function _check_no_inf(col::AbstractVector, what)
    iscontinuous(col) || return nothing
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
    return iscontinuous(col) ? _narrow_nonmissing(filtered) : filtered
end

_row_aligned(col, nrows) = col isa AbstractVector && length(col) == nrows

# Drop rows where any continuous column in `positional` or `named` contains
# `missing` or `NaN`. Categorical columns (per `iscontinuous`) are never
# filtered (a `missing` there is treated as a value, not as no-data) but get
# the same row mask applied so their rows stay aligned with the continuous
# columns. Throws on any `Inf`/`-Inf` remaining in a continuous column.
# Continuous `Union{Missing,T}` element types are narrowed to `T` after
# filtering. `positional` is iterated as a generic collection so this method
# does not recompile per positional-tuple shape; the per-column work is
# delegated to specialized inner helpers.
function _drop_missing_nan_rows(positional, named::AbstractDictionary)
    isempty(positional) && return positional, named
    nrows = length(first(positional))
    keep = trues(nrows)
    for col in positional
        _accumulate_keep!(keep, col)
    end
    for (_, col) in pairs(named)
        _row_aligned(col, nrows) || continue
        _accumulate_keep!(keep, col)
    end

    new_positional = Any[
        _filter_and_check(col, keep, "positional column $idx")
            for (idx, col) in enumerate(positional)
    ]

    new_named = named
    for (k, col) in pairs(named)
        _row_aligned(col, nrows) || continue
        new_named = set(new_named, k => _filter_and_check(col, keep, "named column `$(k)`"))
    end
    return new_positional, new_named
end
