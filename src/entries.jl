const PlotType = Type{<:Plot}

"""
    Entry(plottype::PlotType, positional::Arguments, named::NamedArguments)

Define plottype as well as positional and named arguments for a single plot.
"""
struct Entry
    plottype::PlotType
    positional::Arguments
    named::NamedArguments
end

function Base.get(entry::Entry, key::Int, default)
    return get(entry.positional, key, default)
end

function Base.get(entry::Entry, key::Symbol, default)
    return get(entry.named, key, default)
end

function Base.append!(e1::Entry, e2::Entry)
    plottype = assert_equal(e1.plottype, e2.plottype)
    positional = map(append!, e1.positional, e2.positional)
    named = map(append_or_assertequal!, e1.named, e2.named)
    return Entry(plottype, positional, named)
end

# Use technique from https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/289
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
    categoricalscales::Dictionary{KeyType, CategoricalScale}
    continuousscales::Dictionary{KeyType, ContinuousScale}
end

"""
    AxisEntries(axis::Union{Axis, Nothing}, entries::Vector{Entry}, categoricalscales, continuousscales)

Define all ingredients to make plots on an axis.
Each categorical scale should be a `CategoricalScale`, and each continuous
scale should be a `ContinuousScale`.
"""
struct AxisEntries
    axis::Union{Axis, Axis3}
    entries::Vector{Entry}
    categoricalscales::Dictionary{KeyType, CategoricalScale}
    continuousscales::Dictionary{KeyType, ContinuousScale}
end

function AxisEntries(ae::AxisSpecEntries, fig)
    ax = ae.axis.type(fig[ae.axis.position...]; pairs(ae.axis.attributes)...)
    AxisEntries(ax, ae.entries, ae.categoricalscales, ae.continuousscales)
end

function AxisEntries(ae::AxisSpecEntries, ax::Union{Axis, Axis3})
    AxisEntries(ax, ae.entries, ae.categoricalscales, ae.continuousscales)
end

function Makie.plot!(ae::AxisEntries)
    axis, entries = ae.axis, ae.entries
    for entry in entries
        plot = entry.plottype(Tuple(entry.positional), Dict{Symbol, Any}(pairs(entry.named)))
        plot!(axis, plot)
    end
    return ae
end

entries(grid::AbstractMatrix{AxisEntries}) = Iterators.flatten(ae.entries for ae in grid)
entries(grid::AbstractMatrix{AxisSpecEntries}) = Iterators.flatten(ae.entries for ae in grid)

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

Base.iterate(fg::FigureGrid) = iterate((fg.figure, fg.grid))
Base.iterate(fg::FigureGrid, i) = iterate((fg.figure, fg.grid), i)
