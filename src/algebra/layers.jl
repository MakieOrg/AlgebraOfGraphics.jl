struct Layers
    layers::Vector{Layer}
end

Base.convert(::Type{Layers}, s::Layer) = Layers([s])
Base.convert(::Type{Layers}, s::Layers) = s

Base.getindex(v::Layers, i::Int) = v.layers[i]
Base.length(v::Layers) = length(v.layers)
Base.eltype(::Type{Layers}) = Layer
Base.iterate(v::Layers, args...) = iterate(v.layers, args...)

const OneOrMoreLayers = Union{Layers, Layer}

function Base.:+(s1::OneOrMoreLayers, s2::OneOrMoreLayers)
    l1::Layers, l2::Layers = s1, s2
    return Layers(vcat(l1.layers, l2.layers))
end

function Base.:*(s1::OneOrMoreLayers, s2::OneOrMoreLayers)
    l1::Layers, l2::Layers = s1, s2
    return Layers([el1 * el2 for el1 in l1 for el2 in l2])
end

# function summary(e::Entry)
#     summaries = Dict{KeyType, Any}()
#     for (i, tup) in enumerate((e.primary, e.positional, e.named))
#         for (key, val) in pairs(tup)
#             summaries[key] = if i == 1
#                 [val]
#             elseif iscontinuous(val)
#                 Makie.extrema_nan(val)
#             elseif i == 2 && isgeometry(val)
#                 nothing
#             else
#                 collect(uniquesorted(vec(val)))
#             end
#         end
#     end
#     return Entry(e; summaries)
# end

uniquevalues(v::ArrayLike) = collect(uniquesorted(vec(v)))

function uniquevalues(e::Entry)
    uv = Dict{KeyType, Any}()
    for (key, val) in pairs(e.primary)
        uv[key] = uniquevalues(val)
    end
    for (key, val) in pairs(e.positional)
        uv[key] = mapreduce(uniquevalues, mergesorted, val)
    end
    return uv
end

mergesummaries(s1::AbstractVector, s2::AbstractVector) = mergesorted(s1, s2)
mergesummaries(s1::Tuple, s2::Tuple) = extend_extrema(s1, s2)
mergesummaries(::Nothing, ::Nothing) = nothing

mergelabels(a, b) = a

layoutkeys(entry::Entry) = layoutkeys(entry.primary, shape(entry))

function layoutkeys(primary, shp)
    return map(CartesianIndices(shp)) do c
        nt = map(v -> v[c], primary)
        ks = filter(in((:row, :col, :layout)), keys(nt))
        return NamedTuple{(ks)}(nt)
    end
end

function compute_grid_positions(scales, primary=(;))
    return map((:row, :col), (first, last)) do sym, f
        scale = get(scales, sym, nothing)
        lscale = get(scales, :layout, nothing)
        return if !isnothing(scale)
            rg = Base.OneTo(maximum(scale.plot))
            haskey(primary, sym) ? rg : rescale(fill(primary[sym]), scale)
        elseif !isnothing(lscale)
            rg = Base.OneTo(maximum(f, lscale.plot))
            haskey(primary, :layout) ? rg : rescale(fill(primary[:layout]), lscale)
        else
            Base.OneTo(1)
        end
    end
end

function compute_axes_grid(fig, s::OneOrMoreLayers;
                           axis=NamedTuple(), palettes=NamedTuple())
    layers::Layers = s
    entries = map(process, layers)
    uv = mapreduce(uniquevalues, mergewith!(mergesummaries), entries)

    # summaries = mapfoldl(
    #     entry -> entry.summaries,
    #     mergewith!(mergesummaries),
    #     entries,
    #     init=Dict{KeyType, Any}()
    # )

    palettes = merge(default_palettes(), palettes)
    scales = default_scales(uv, palettes)

    axs = compute_grid_positions(scales)

    axes_grid = map(CartesianIndices(axs)) do c
        type = get(axis, :type, Axis)
        options = Base.structdiff(axis, (; type))
        ax = type(fig[Tuple(c)...]; options...)
        return AxisEntries(ax, Entry[], scales, Dict{KeyType, Any}())
    end

    for e in entries
        for c in CartesianIndices(shape(e))
            primary, positional, named = map((e.primary, e.positional, e.named)) do tup
                return map(v -> v[c], tup)
            end
            rows, cols = compute_grid_positions(scales, primary)
            entry = Entry(e; primary, positional, named)
            labels = copy(e.labels)
            map!(values(labels)) do l
                ls = Broadcast.broadcastable(l)
                return ls[Broadcast.newindex(ls, c)]
            end
            for i in rows, j in cols
                ae = axes_grid[i, j]
                push!(ae.entries, entry)
                mergewith!(mergelabels, ae.labels, labels)
            end
        end
    end

    # Link colors
    labeledcolorbar = getlabeledcolorbar(axes_grid)
    if !isnothing(labeledcolorbar)
        _, colorbar = labeledcolorbar
        colorrange = colorbar.extrema
        for entry in AlgebraOfGraphics.entries(axes_grid)
            entry.attributes[:colorrange] = colorrange
        end
    end

    return axes_grid

end

function Makie.plot!(fig, s::OneOrMoreLayers;
                                axis=NamedTuple(), palettes=NamedTuple())
    grid = compute_axes_grid(fig, s; axis, palettes)
    foreach(plot!, grid)
    return grid
end

function Makie.plot(s::OneOrMoreLayers;
                               axis=NamedTuple(), figure=NamedTuple(), palettes=NamedTuple())
    fig = Figure(; figure...)
    grid = plot!(fig, s; axis, palettes)
    return FigureGrid(fig, grid)
end

# Convenience function, which may become superfluous if `plot` also calls `facet!`
function draw(s::OneOrMoreLayers;
              axis = NamedTuple(), figure=NamedTuple(), palettes=NamedTuple())
    fg = plot(s; axis, figure, palettes)
    facet!(fg)
    Legend(fg)
    resizetocontent!(fg)
    return fg
end

function draw!(fig, s::OneOrMoreLayers;
               axis=NamedTuple(), palettes=NamedTuple())
    ag = plot!(fig, s; axis, palettes)
    facet!(fig, ag)
    return ag
end