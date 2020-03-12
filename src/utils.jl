concatenate(v::Union{Tuple, NamedTuple}...) = map(concatenate, v...)
concatenate(v::AbstractArray...) = vcat(v...)

ncols(v::Tuple) = length(v)
ncols(v::AbstractVector) = 1
ncols(v::AbstractArray) = mapreduce(length, *, tail(axes(v)))

column_length(v::Union{Tuple, NamedTuple}) = column_length(v[1])
column_length(v::AbstractVector) = length(v)
column_length(v::AbstractArray) = length(axes(v, 1))

extract_view(v::Union{Tuple, NamedTuple}, idxs) = map(x -> extract_view(x, idxs), v)
extract_view(v::AbstractVector, idxs) = view(v, idxs)
function extract_view(v::AbstractArray{<:Any, N}, idxs) where {T, N}
    args = ntuple(i -> i == 1 ? idxs : Colon(), N)
    view(v, args...)
end
function extract_view(v::Select, idxs)
    Select(
           map(x -> extract_view(x, idxs), v.args)...;
           map(x -> extract_view(x, idxs), v.kwargs)...
          )
end

extract_view(v::Union{Tuple, NamedTuple}, idxs, n) = extract_view(v[n], idxs)
extract_view(v::AbstractVector, idxs, n) = view(v, idxs)
function extract_view(v::AbstractArray, idxs, n)
    ax = tail(axes(v))
    c = CartesianIndices(ax)[n]
    view(v, idxs, Tuple(c)...)
end
function extract_view(v::Select, idxs, n)
    Select(
           map(x -> extract_view(x, idxs, n), v.args)...;
           map(x -> extract_view(x, idxs, n), v.kwargs)...
          )
end

extract_column(t, c::Union{Tuple, NamedTuple}) = map(x -> extract_column(t, x), c)
extract_column(t, col::AbstractVector) = col
extract_column(t, col::Symbol) = getproperty(t, col)
extract_column(t, col::Integer) = getindex(t, col)
extract_column(t, col::AbstractArray) =
    mapslices(v -> extract_column(t, v[1]), col, dims = 1)

extract_columns(t, tup::Union{Tuple, NamedTuple}) = map(col -> extract_column(t, col), tup)

# show utils

function _show(io::IO, args...; kwargs...)
    print(io, "(")
    kwargs = values(kwargs)
    na, nk = length(args), length(kwargs)
    for i in 1:na
        show(io, args[i])
        if i < na + nk
            print(io, ", ")
        end
    end
    for i in 1:nk
        print(io, keys(kwargs)[i])
        print(io, " = ")
        show(io, kwargs[i])
        if i < nk
            print(io, ", ")
        end
    end
    print(io, ")")
end
