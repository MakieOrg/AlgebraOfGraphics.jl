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

uniquevalues(v::ArrayLike) = collect(uniquesorted(vec(v)))

function uniquevalues(e::Entry)
    uv = Dict{KeyType, Any}()
    for (key, val) in pairs(e.primary)
        uv[key] = uniquevalues(val)
    end
    for (key, val) in pairs(e.positional)
        all(iscontinuous, val) && continue
        all(isgeometry, val) && continue
        uv[key] = mapreduce(uniquevalues, mergesorted, val)
    end
    return uv
end

function extremas(e::Entry)
    es = Dict{KeyType, Any}()
    for tup in (e.positional, e.named)
        for (key, val) in pairs(tup)
            all(iscontinuous, val) || continue
            es[key] = mapreduce(Makie.extrema_nan, extend_extrema, val)
        end
    end
    return es
end

function compute_grid_positions(scales, primary=(;))
    return map((:row, :col), (first, last)) do sym, f
        scale = get(scales, sym, nothing)
        lscale = get(scales, :layout, nothing)
        return if !isnothing(scale)
            rg = Base.OneTo(maximum(scale.plot))
            haskey(primary, sym) ? rescale(fill(primary[sym]), scale) : rg
        elseif !isnothing(lscale)
            rg = Base.OneTo(maximum(f, lscale.plot))
            haskey(primary, :layout) ? map(f, rescale(fill(primary[:layout]), lscale)) : rg
        else
            Base.OneTo(1)
        end
    end
end

function compute_axes_grid(fig, s::OneOrMoreLayers;
                           axis=NamedTuple(), palettes=NamedTuple())
    layers::Layers = s
    entries = map(process, layers)
    
    uv = mapreduce(uniquevalues, mergewith!(mergesorted), entries)
    es = mapreduce(extremas, mergewith!(extend_extrema), entries)

    theme_palettes = NamedTuple(Makie.current_default_theme()[:palette])
    palettes = merge((layout=wrap,), map(to_value, theme_palettes), palettes)
    scales = default_scales(merge(es, uv), palettes)

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
                return map(v -> getnewindex(v, c), tup)
            end
            rows, cols = compute_grid_positions(scales, primary)
            entry = Entry(e; primary, positional, named)
            labels = copy(e.labels)
            map!(l -> getnewindex(l, c), values(labels))
            for i in rows, j in cols
                ae = axes_grid[i, j]
                push!(ae.entries, entry)
                merge!((a, b) -> isequal(a, b) ? a : "", ae.labels, labels)
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

    # Axis labels and ticks
    for ae in axes_grid
        # TODO: support log colorscale
        ndims = isaxis2d(ae) ? 2 : 3
        for (i, var) in zip(1:ndims, (:x, :y, :z))
            label, scale = get(ae.labels, i, nothing), get(ae.scales, i, nothing)
            any(isnothing, (label, scale)) && continue
            for (k′, v) in pairs((label=string(label), ticks=ticks(scale)))
                k = Symbol(var, k′)
                k in keys(axis) || (getproperty(Axis(ae), k)[] = v)
            end
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