struct Entry
    plottype::PlotFunc
    positional::Tuple
    named::NamedTuple
    attributes::Dict{Symbol, Any}
end

Entry(plottype::PlotFunc=Any, positional::Tuple=(), named::NamedTuple=(;); attributes...) =
    Entry(plottype, positional, named, Dict{Symbol, Any}(attributes))

Entry(positional::Tuple, named::NamedTuple=(;); attributes...) =
    Entry(Any, positional, named; attributes...)

Entry(named::NamedTuple; attributes...) = Entry(Any, (), named; attributes...)

function separate(entry::Entry)
    named = entry.named
    discrete_keys = filter(keys(named)) do key
        return !iscontinuous(named[key])
    end
    discrete = NamedTuple{discrete_keys}(named)
    continuous = Base.structdiff(named, discrete)
    return discrete => Entry(entry.plottype, entry.positional, continuous, entry.attributes)
end

function recombine(discrete, entry::Entry)
    return Entry(
        entry.plottype,
        entry.positional,
        merge(discrete, entry.named),
        entry.attributes
    )
end

const ArgDict = Dict{Union{Symbol, Int}, Any}

struct Entries
    entries::Vector{Entry}
    scales::ArgDict
    labels::ArgDict
end

Entries() = Entries(Entry[], argdict(), argdict())

function compute_axes_grid(fig, e::Entries; axis=NamedTuple())

    rowcol = (:row, :col)

    layout_scale, scales... = map((:layout, rowcol...)) do sym
        return get(e.scales, sym, nothing)
    end

    grid_size = map(scales, (first, last)) do scale, f
        isnothing(scale) || return maximum(scale.plot)
        isnothing(layout_scale) || return maximum(f, layout_scale.plot)
        return 1
    end

    axes_grid = map(CartesianIndices(grid_size)) do c
        type = get(axis, :type, Axis)
        options = Base.structdiff(axis, (; type))
        ax = type(fig[Tuple(c)...]; options...)
        return AxisEntries(ax, Entry[], e.scales, e.labels)
    end

    for entry in e.entries
        rows, cols = map(rowcol, scales, (first, last)) do sym, scale, f
            v = get(entry.mappings, sym, nothing)
            layout_v = get(entry.mappings, :layout, nothing)
            # without layout info, plot on all axes
            # all values in `v` and `layout_v` are equal
            isnothing(v) || return rescale(v[1:1], scale)
            isnothing(layout_v) || return map(f, rescale(layout_v[1:1], layout_scale))
            return 1:f(grid_size)
        end
        for i in rows, j in cols
            ae = axes_grid[i, j]
            push!(ae.entries, entry)
        end
    end

    # Link colors
    labeledcolorbar = getlabeledcolorbar(axes_grid)
    if !isnothing(labeledcolorbar)
        colorrange = getvalue(labeledcolorbar).extrema
        for entry in entries(axes_grid)
            entry.attributes[:colorrange] = colorrange
        end
    end

    return axes_grid

end

function AbstractPlotting.plot(entries::Entries; axis=NamedTuple(), figure=NamedTuple())
    fig = Figure(; figure...)
    grid = plot!(fig, entries; axis)
    return FigureGrid(fig, grid)
end

function AbstractPlotting.plot!(fig, entries::Entries; axis=NamedTuple())
    axes_grid = compute_axes_grid(fig, entries; axis)
    foreach(plot!, axes_grid)
    return axes_grid
end

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
    scales::ArgDict
    labels::ArgDict
end

AbstractPlotting.Axis(ae::AxisEntries) = ae.axis
Entries(ae::AxisEntries) = Entries(ae.entries, ae.labels, ae.scales)

function prefix(i::Int, sym::Symbol)
    var = (:x, :y, :z)[i]
    return Symbol(var, sym)
end

# Slightly complex machinery to recombine stacked barplots
function mustbemerged(e::Entry)
    isbarplot = e.plottype <: BarPlot
    hasstack = :stack in keys(e.mappings.named) || :stack in keys(e.attributes)
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

function AbstractPlotting.plot!(ae::AxisEntries)
    axis, entries, labels, scales = ae.axis, ae.entries, ae.labels, ae.scales
    for entry in combine(entries)
        plottype, mappings, attributes = entry.plottype, entry.mappings, entry.attributes
        trace = map(unwrap∘rescale, mappings, scales)
        positional, named = trace.positional, trace.named
        merge!(named, attributes)

        # Remove layout info
        for sym in [:col, :row, :layout]
            pop!(named, sym, nothing)
        end

        # Implement defaults
        for (key, val) in pairs(default_styles())
            key == :color && has_zcolor(entry) && continue # do not overwrite contour color
            get!(named, key, val)
        end

        # Set dodging information
        dodge = get(scales, :dodge, nothing)
        isa(dodge, CategoricalScale) && (named[:n_dodge] = maximum(dodge.plot))

        # Implement alpha transparency
        alpha = pop!(named, :alpha, nothing)
        color = get(named, :color, nothing)
        !isnothing(color) && alpha isa Number && (named[:color] = (color, alpha))

        plot!(plottype, axis, positional...; named...)
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