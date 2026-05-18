_is_missing_or_nan(::Missing) = true
_is_missing_or_nan(v::Number) = isnan(v)
_is_missing_or_nan(_) = false

_is_inf(v::Number) = isinf(v)
_is_inf(_) = false

function _narrow_nonmissing(v::AbstractVector)
    T = Base.nonmissingtype(eltype(v))
    T === eltype(v) && return v
    return Vector{T}(v)
end

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

# Categorical columns are never filtered themselves — `missing` is a value
# there — but get the same row mask so they stay aligned with continuous
# columns.
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
