const KeyType = Union{Symbol, Int}

struct Entry
    plottype::PlotFunc
    primary::NamedTuple
    positional::Tuple
    named::NamedTuple
    scales::Dict{KeyType, Any}
    labels::Dict{KeyType, Any}
    attributes::Dict{Symbol, Any}
end

function Entry(plottype::PlotFunc, primary::NamedTuple, positional::Tuple, named::NamedTuple, labels=Dict{KeyType, Any}(); attributes...)
    scales, attributes = Dict{KeyType, Any}(), Dict{Symbol, Any}(attributes)
    return Entry(plottype, primary, positional, named, scales, labels, attributes)
end

Entry(primary::NamedTuple, positional::Tuple, named::NamedTuple, labels=Dict{KeyType, Any}(); attributes...) =
    Entry(Any, primary, positional, named, labels; attributes...)

"""
    AxisEntries(axis::Union{Axis, Nothing}, entries::Vector{Entry}, labels, scales)

Define all ingredients to make plots on an axis.
Each scale can be either a `CategoricalScale` (for discrete collections), such as
`CategoricalScale(["a", "b"], ["red", "blue"])`, or a function,
such as `log10`. Other scales may be supported in the future.
"""
struct AxisEntries
    axis::Union{Axis, Axis3}
    entries::Vector{Entry}
    scales::Dict{KeyType, Any}
    labels::Dict{KeyType, Any}
end

AbstractPlotting.Axis(ae::AxisEntries) = ae.axis

function prefix(i::Int, sym::Symbol)
    var = (:x, :y, :z)[i]
    return Symbol(var, sym)
end

# Slightly complex machinery to recombine stacked barplots
function mustbemerged(e::Entry)
    isbarplot = e.plottype <: BarPlot
    hasstack = :stack in keys(e.named) || :stack in keys(e.attributes)
    return isbarplot && hasstack
end

# Combine both entries as a unique entry with longer data
function stack!(e1::Entry, e2::Entry)
    p1, p2 = e1.plottype, e2.plottype
    m1, m2 = e1.mappings, e2.mappings
    a1, a2 = e1.attributes, e2.attributes
    l1, l2 = length(m1[1]), length(m2[1])
    assert_equal(p1, p2)
    for (k, v) in pairs(a1)
        assert_equal(v, a2[k])
    end
    mergewith!(m1, m2) do v1, v2
        long1 = size(v1) == () ? fill(v1[], l1) : v1
        long2 = size(v2) == () ? fill(v2[], l2) : v2
        return vcat(long1, long2)
    end
    return e1
end

function combine(entries::AbstractVector{Entry})
    combinedentries = Entry[]
    for entry in entries
        idx = findfirst(mustbemerged, combinedentries)
        if !isnothing(idx) && mustbemerged(entry)
            stack!(combinedentries[idx], entry)
        else
            push!(combinedentries, entry)
        end
    end
    return combinedentries
end

mapkeys(f, tup::Tuple) = map(f, keys(tup))
mapkeys(f, ::NamedTuple{names}) where {names} = NamedTuple{names}(map(f, names))

function AbstractPlotting.plot!(ae::AxisEntries)
    axis, entries, labels, scales = ae.axis, ae.entries, ae.labels, ae.scales
    for entry in combine(entries)
        plottype, attributes = entry.plottype, copy(entry.attributes)
        positional, named = map((entry.positional, entry.named)) do tup
            return mapkeys(tup) do key
                return unwrap(rescale(tup[key], scales[key]))
            end
        end
        merge!(attributes, pairs(named))

        # Remove layout info
        for sym in [:col, :row, :layout]
            pop!(attributes, sym, nothing)
        end

        # Implement defaults
        for (key, val) in pairs(default_styles())
            key == :color && has_zcolor(entry) && continue # do not overwrite contour color
            get!(attributes, key, val)
        end

        # Set dodging information
        dodge = get(scales, :dodge, nothing)
        isa(dodge, CategoricalScale) && (attributes[:n_dodge] = maximum(dodge.plot))

        # Implement alpha transparency
        alpha = pop!(attributes, :alpha, nothing)
        color = get(attributes, :color, nothing)
        !isnothing(color) && alpha isa Number && (attributes[:color] = (color, alpha))

        plot!(plottype, axis, positional...; attributes...)
    end
    # TODO: support log colorscale
    ndims = isaxis2d(ae) ? 2 : 3
    for i in 1:ndims
        label, scale = get(labels, i, nothing), get(scales, i, nothing)
        any(isnothing, (label, scale)) && continue
        axislabel, axisticks, axisscale = prefix.(i, (:label, :ticks, :scale))
        getproperty(axis, axisticks)[] = ticks(scale)
        getproperty(axis, axislabel)[] = string(label)
    end
    return axis
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