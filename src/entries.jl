const KeyType = Union{Symbol, Int}

Base.@kwdef struct Entry
    plottype::PlotFunc=Any
    primary::NamedTuple=(;)
    positional::Tuple=()
    named::NamedTuple=(;)
    labels::Dict{KeyType, Any}=Dict{KeyType, Any}()
    attributes::Dict{Symbol, Any}=Dict{Symbol, Any}()
end

function Base.get(e::Entry, key::Int, default)
    return key in keys(e.positional) ? e.positional[key] : default
end

function Base.get(e::Entry, key::Symbol, default)
    return get(e.named, key, default)
end

function Entry(e::Entry; kwargs...)
    nt = (; e.plottype, e.primary, e.positional, e.named, e.labels, e.attributes)
    return Entry(; merge(nt, values(kwargs))...)
end

function Base.map(f, e::Entry)
    axs = shape(e)
    outputs = map(CartesianIndices(axs)) do c
        p = map(v -> getnewindex(v, c), e.positional)
        n = map(v -> getnewindex(v, c), e.named)
        return f(p, n)
    end
    positional = components(StructArray(map(first, outputs)))
    named = components(StructArray(map(last, outputs)))
    return Entry(e; positional, named)
end

"""
    AxisEntries(axis::Union{Axis, Nothing}, entries::Vector{Entry}, scales)

Define all ingredients to make plots on an axis.
Each scale should be a `CategoricalScale`.
"""
struct AxisEntries
    axis::Union{Axis, Axis3}
    entries::Vector{Entry}
    scales::Dict{KeyType, Any}
end

Makie.Axis(ae::AxisEntries) = ae.axis

# Slightly complex machinery to recombine stacked barplots
function mergeable(e1::Entry, e2::Entry)
    for e in (e1, e2)
        e.plottype <: BarPlot || return false
        haskey(e.primary, :stack) || return false
    end
    return true
end

function lengthen_primary(e::Entry)
    N = length(first(e.positional))
    primary = map(t -> fill(t, N), e.primary)
    return Entry(e; primary)
end

function maybecollapse(v::AbstractArray)
    f = first(v)
    return all(isequal(f), v) ? fill(f) : v
end

# Combine entries as a unique entry with longer data
function stack(short_entries::AbstractVector{Entry})
    entries = map(lengthen_primary, short_entries)
    primary = map(maybecollapse∘vcat, map(entry -> entry.primary, entries)...)
    positional = map(vcat, map(entry -> entry.positional, entries)...)
    named = map(vcat, map(entry -> entry.named, entries)...)
    return Entry(first(entries); primary, positional, named)
end

mapkeys(f, tup::Tuple) = ntuple(f, length(tup))
mapkeys(f, ::NamedTuple{names}) where {names} = NamedTuple{names}(map(f, names))

function Makie.plot!(ae::AxisEntries)
    axis, entries, scales = ae.axis, ae.entries, ae.scales
    i, N = 1, length(entries)
    while i ≤ N
        j = i + 1
        while j ≤ N && mergeable(entries[i], entries[j])
            j += 1
        end
        entry, i = stack(entries[i:j-1]), j
        attributes = copy(entry.attributes)
        primary, positional, named = map((entry.primary, entry.positional, entry.named)) do tup
            return mapkeys(tup) do key
                rescaled = rescale(tup[key], get(scales, key, nothing))
                return haszerodims(rescaled) ? rescaled[] : rescaled
            end
        end
        merge!(attributes, pairs(primary), pairs(named))

        # Remove layout info
        for sym in [:col, :row, :layout]
            pop!(attributes, sym, nothing)
        end

        # Avoid automated cycling
        get!(attributes, :cycle, nothing)

        # Set dodging information
        dodge = get(scales, :dodge, nothing)
        isa(dodge, CategoricalScale) && (attributes[:n_dodge] = maximum(plotvalues(dodge)))

        # Implement alpha transparency
        alpha = pop!(attributes, :alpha, nothing)
        color = get(attributes, :color, nothing)
        !isnothing(color) && alpha isa Number && (attributes[:color] = (color, alpha))

        plottype = Makie.plottype(entry.plottype, positional...)
        plot!(plottype, axis, positional...; attributes...)
    end
    return ae
end

entries(grid::AbstractMatrix{AxisEntries}) = Iterators.flatten(ae.entries for ae in grid)

struct FigureGrid
    figure::Figure
    grid::Matrix{AxisEntries}
end

Base.show(io::IO, fg::FigureGrid) = show(io, fg.figure)
Base.show(io::IO, m::MIME, fg::FigureGrid) = show(io, m, fg.figure)
Base.show(io::IO, ::MIME"text/plain", fg::FigureGrid) = print(io, "FigureGrid()")

Base.showable(mime::MIME{M}, fg::FigureGrid) where {M} = showable(mime, fg.figure)

Base.display(fg::FigureGrid) = display(fg.figure)

function FileIO.save(filename::String, fg::FigureGrid; kwargs...)
    return FileIO.save(FileIO.query(filename), fg; kwargs...)
end

function FileIO.save(file::FileIO.Formatted, fg::FigureGrid; kwargs...)
    return FileIO.save(file, fg.figure; kwargs...)
end

to_tuple(fg) = (fg.figure, fg.grid)

Base.iterate(fg::FigureGrid) = iterate(to_tuple(fg))
Base.iterate(fg::FigureGrid, i) = iterate(to_tuple(fg), i)