function colorbar!(fg::FigureGrid; position=:right,
                   vertical=default_isvertical(position), kwargs...)

    guide_pos = guides_position(fg.figure, position)
    return colorbar!(guide_pos, fg; vertical, kwargs...)
end

"""
    colorbar!(figpos, grid; kwargs...)

Compute colorbar for `grid` (which should be the output of [`draw!`](@ref)) and draw it in
position `figpos`. Attributes allowed in `kwargs` are the same as `MakieLayout.Colorbar`.
"""
function colorbar!(figpos, grid; kwargs...)
    colorbar = compute_colorbar(grid)
    return isnothing(colorbar) ? nothing : Colorbar(figpos; colorbar..., kwargs...)
end

compute_colorbar(fg::FigureGrid) = compute_colorbar(fg.grid)

function should_use_colorbar(colorscale::CategoricalScale)::Bool
    aesprops::CategoricalAesProps = colorscale.props.aesprops
    return aesprops.colorbar === Makie.automatic ? is_binned(colorscale) : aesprops.colorbar
end

function compute_colorbar(grid::Matrix{AxisEntries})
    catscales = get(first(grid).categoricalscales, AesColor, nothing)
    if catscales !== nothing
        for catscale in catscales
            if should_use_colorbar(catscale)
                return categorical_colorbar(catscale)
            end
        end
    end
    colorscales = filter(!isnothing, [get(ae.continuousscales, AesColor, nothing) for ae in grid])
    isempty(colorscales) && return

    # colorscale = reduce(mergescales, colorscales)
    colorscale_dict = reduce(colorscales, init=Dictionary{Union{Nothing,Symbol},ContinuousScale}()) do c1, c2
        mergewith!(mergescales, c1, c2)
    end

    if length(colorscale_dict) > 1
        error("Cannot yet handle multiple colorscales, found $colorscale_dict")
    end

    colorscale = only(values(colorscale_dict))
    
    return continuous_colorbar(colorscale)
end

function continuous_colorbar(colorscale::ContinuousScale)
    label = getlabel(colorscale)
    limits = @something colorscale.props.aesprops.colorrange colorscale.extrema
    is_highclipped = limits[2] < colorscale.extrema[2]
    is_lowclipped = limits[1] > colorscale.extrema[1]

    _, limits = strip_units(colorscale, collect(limits))

    colormap = @something colorscale.props.aesprops.colormap default_colormap()
    colormap_colors = Makie.to_colormap(colormap)

    lowclip = is_lowclipped ? @something(colorscale.props.aesprops.lowclip, colormap_colors[1]) : Makie.automatic
    highclip = is_highclipped ? @something(colorscale.props.aesprops.highclip, colormap_colors[end]) : Makie.automatic

    return (;
        label,
        limits,
        colormap,
        lowclip,
        highclip,
    )
end

function is_binned(scale::CategoricalScale)
    all(x -> x isa Bin, datavalues(scale))
end

function categorical_colorbar(scale::CategoricalScale)
    pv = plotvalues(scale)
    dv = datavalues(scale)
    label = getlabel(scale)

    if is_binned(scale)
        bins = sort(dv, by = x -> x.range[2])
        colors = RGBAf[]
        values = eltype(bins[1].range)[]
        for i in eachindex(bins)
            bin = bins[i]
            if i == 1
                push!(values, bin.range...)
                push!(colors, pv[i])
            else
                prev_bin = bins[i-1]
                # if bins don't touch, we have to insert transparent gaps in between
                if prev_bin.range[2] > bin.range[1]
                    error("Overlapping bins in categorical colorscale: $(prev_bin.range) and $(bin.range).")
                elseif prev_bin.range[2] < bin.range[1]
                    push!(values, bin.range[1])
                    push!(colors, RGBAf(0, 0, 0, 0))
                end
                push!(values, bin.range[2])
                push!(colors, pv[i])
            end
        end

        if !isfinite(values[1])
            lowclip = popfirst!(colors)
            popfirst!(values)
        else
            lowclip = nothing
        end

        if !isfinite(values[end])
            highclip = pop!(colors)
            pop!(values)
        else
            highclip = nothing
        end

        limits = extrema(values)
        cgrad_stops = (values .- limits[1]) ./ (limits[2] - limits[1])
        colormap = cgrad(colors, cgrad_stops; categorical = true)
        return (;
            limits,
            colormap,
            label,
            lowclip,
            highclip,
        )
    else
        limits = (0.5, length(pv) + 0.5)
        # reverse so values read top-to-bottom
        ticks = (1:length(pv), reverse(datalabels(scale)))
        colormap = cgrad(reverse(pv), range(0, 1, length = length(pv) + 1); categorical = true)
        return (;
            limits,
            colormap,
            ticks,
            label,
        )
    end
    
end
