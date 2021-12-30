"""
    Entry(plottype::PlotFunc, positional::Arguments, named::NamedArguments)

Define plottype as well as positional and named arguments for a single plot.
"""
struct Entry
    plottype::PlotFunc
    positional::Arguments
    named::NamedArguments
end

# Use technique from https://github.com/JuliaPlots/AlgebraOfGraphics.jl/pull/289
# to encode all axis information without creating the axis.
struct AxisSpec
    type::Union{Type{Axis}, Type{Axis3}}
    position::Tuple{Int,Int}
    attributes::NamedArguments
end

extract_type(; type=Axis, options...) = type, NamedArguments(options)

function AxisSpec(position, options)
    type, attributes = extract_type(; pairs(options)...)
    return AxisSpec(type, Tuple(position), attributes)
end

struct AxisSpecEntries
    axis::AxisSpec
    entries::Vector{Entry}
    scales::MixedArguments
end

"""
    AxisEntries(axis::Union{Axis, Nothing}, entries::Vector{Entry}, scales)

Define all ingredients to make plots on an axis.
Each scale should be a `CategoricalScale`.
"""
struct AxisEntries
    axis::Union{Axis, Axis3}
    entries::Vector{Entry}
    scales::MixedArguments
end

function AxisEntries(ae::AxisSpecEntries, fig)
    ax = ae.axis.type(fig[ae.axis.position...]; ae.axis.attributes...)
    AxisEntries(ax, ae.entries, ae.scales)
end

function AxisEntries(ae::AxisSpecEntries, ax::Union{Axis,Axis3})
    if !isempty(ax)
        @warn("Axis got passed, but also axis attributes. Ignoring axis attributes $(a.axis.attributes)")
    end
    AxisEntries(ax, ae.entries, ae.scales)
end

# Slightly complex machinery to recombine stacked barplots
function mergeable(e1::Entry, e2::Entry)
    for e in (e1, e2)
        e.plottype <: BarPlot || return false
        haskey(e.named, :stack) || return false
    end
    return true
end

function lengthen_primary(e::Entry)
    plottype, positional = e.plottype, e.positional
    N = length(first(positional))
    named = map(v -> haszerodims(v) ? fill(v[], N) : v, e.named)
    return Entry(plottype, positional, named)
end

# Combine entries as a unique entry with longer data
function stack(short_entries::AbstractVector{Entry})
    entry = first(short_entries)
    length(short_entries) == 1 && return entry
    entries = map(lengthen_primary, short_entries)
    # TODO: avoid splatting here
    positional = map(vcat, map(entry -> entry.positional, entries)...)
    named = map(vcat, map(entry -> entry.named, entries)...)
    return Entry(entry.plottype, positional, named)
end

function compute_attributes(attributes, primary, named, scales)
    attrs = NamedArguments()
    merge!(attrs, attributes)
    merge!(attrs, primary)
    merge!(attrs, named)

    # implement alpha transparency
    alpha = get(attrs, :alpha, nothing)
    color = get(attrs, :color, nothing)
    if !isnothing(color)
        set!(attrs, :color, isnothing(alpha) ? color : (color, alpha))
    end

    # opt out of the default cycling mechanism
    set!(attrs, :cycle, nothing)

    # compute dodging information
    dodge = get(scales, :dodge, nothing)
    isa(dodge, CategoricalScale) && set!(attrs, :n_dodge, maximum(plotvalues(dodge)))

    # remove unnecessary information
    return unset(attrs, :col, :row, :layout, :alpha)
end

function Makie.plot!(ae::AxisEntries)
    axis, entries = ae.axis, ae.entries
    i, N = 1, length(entries)
    while i ≤ N
        j = i + 1
        while j ≤ N && mergeable(entries[i], entries[j])
            j += 1
        end
        entry, i = stack(entries[i:j-1]), j
        positional = entry.positional
        named = map(v -> haszerodims(v) ? v[] : v, entry.named)
        plottype = Makie.plottype(entry.plottype, positional...)
        plot!(plottype, axis, positional...; pairs(named)...)
    end
    return ae
end

entries(grid::AbstractMatrix{AxisEntries}) = Iterators.flatten(ae.entries for ae in grid)
entries(grid::AbstractMatrix{_AxisEntries_}) = Iterators.flatten(ae.entries for ae in grid)

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
