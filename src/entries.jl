"""
    Entry(plottype::PlotType, positional::Arguments, named::NamedArguments)

Define plottype as well as positional and named arguments for a single plot.
"""
struct Entry
    plottype::PlotType
    positional::Arguments
    named::NamedArguments
end

# Use technique from https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/289
# to encode all axis information without creating the axis.
struct AxisSpec
    type::Type{<: Makie.AbstractAxis}
    position::Tuple{Int,Int}
    attributes::NamedArguments
end

extract_type(; type=Axis, options...) = type, NamedArguments(options)

function AxisSpec(position, options)
    type, attributes = extract_type(; pairs(options)...)
    return AxisSpec(type, Tuple(position), attributes)
end

# each Aesthetic can (potentially) have multiple separate scales associated with it, for example
# two different color scales. For some aesthetics like AesX or AesLayout it doesn't make sense to have more than one.
# Those should trigger meaningful error messages if they are used with multiple scales

struct AxisSpecEntries
    axis::AxisSpec
    entries::Vector{Entry}
    categoricalscales::MultiAesScaleDict{CategoricalScale}
    continuousscales::MultiAesScaleDict{ContinuousScale}
    processedlayers::Vector{ProcessedLayer} # the layers that were used to create the entries, for legend purposes
end

"""
    AxisEntries(axis::Union{Axis, Nothing}, entries::Vector{Entry}, categoricalscales, continuousscales)

Define all ingredients to make plots on an axis.
Each categorical scale should be a `CategoricalScale`, and each continuous
scale should be a `ContinuousScale`.
"""
struct AxisEntries
    axis::Makie.AbstractAxis
    entries::Vector{Entry}
    categoricalscales::MultiAesScaleDict{CategoricalScale}
    continuousscales::MultiAesScaleDict{ContinuousScale}
    processedlayers::Vector{ProcessedLayer} # the layers that were used to create the entries, for legend purposes
end

function AxisEntries(ae::AxisSpecEntries, fig)
    ax = ae.axis.type(fig[ae.axis.position...]; pairs(ae.axis.attributes)...)
    AxisEntries(ax, ae.entries, ae.categoricalscales, ae.continuousscales, ae.processedlayers)
end

function AxisEntries(ae::AxisSpecEntries, ax::Union{Axis, Axis3})
    AxisEntries(ax, ae.entries, ae.categoricalscales, ae.continuousscales, ae.processedlayers)
end

function Makie.plot!(ae::AxisEntries)
    axis, entries = ae.axis, ae.entries
    for entry in entries
        plot = entry.plottype(Tuple(entry.positional), Dict{Symbol, Any}(pairs(entry.named)))
        plot!(axis, plot)
    end
    return ae
end

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
