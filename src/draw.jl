function apply_alpha_transparency!(attrs::Attributes)
    # manually implement alpha values
    c = get(attrs, :color, Observable(:black))
    alpha = get(attrs, :alpha, Observable(1))
    attrs[:color] = c[] isa Union{Tuple, AbstractArray} ? c : lift(tuple, c, alpha)
end

function set_axis_labels!(ax, names)
    for (nm, prop) in zip(names, (:xlabel, :ylabel, :zlabel))
        s = string(nm)
        if hasproperty(ax, prop) && isempty(getproperty(ax, prop)[])
            getproperty(ax, prop)[] = s
        end
    end
end

function set_axis_ticks!(ax, ticks)
    for (tick, prop) in zip(ticks, (:xticks, :yticks, :zticks))
        if hasproperty(ax, prop) && getproperty(ax, prop)[] == automatic
            getproperty(ax, prop)[] = tick
        end
    end
end

function add_facet_labels!(scene, axs, layout_levels;
    facetlayout, axis, spanned_label, Nx, Ny)

    isnothing(layout_levels) && return

    positive_rotation = axis == :x ? 0f0 : π/2f0

    # Facet labels
    lxl = string.(layout_levels)
    for i in eachindex(lxl)
        pos = axis == :x ? (1, i, Top()) : (i, Nx, Right())
        facetlayout[pos...] = Box(
            scene, color = :gray85, strokevisible = true
        ) 
        facetlayout[pos...] = Label(scene, lxl[i],
            rotation = -positive_rotation, padding = (3f0, 3f0, 3f0, 3f0)
        )
    end

    # Shared xlabel
    itr = axis == :x ? axs[end, :] : axs[:, 1]
    group_protrusion = lift(
        (xs...) -> maximum(x -> axis == :x ? x.bottom : x.left, xs),
        (MakieLayout.protrusionsobservable(ax) for ax in itr)...
    )

    padding = lift(group_protrusion) do val
        val += 10f0
        axis == :x ? (0f0, 0f0, 0f0, val) : (0f0, val, 0f0, 0f0)
    end

    if !isnothing(spanned_label)
        label = Label(scene, spanned_label, padding = padding, rotation = positive_rotation)
        pos = axis == :x ? (Ny, :, Bottom()) : (:, 1, Left())
        facetlayout[pos...] = label
    end
end

# Return the only unique value of the collection if it exists and is nonempty,
# `nothing` otherwise.
function unique_value(labels)
    l = first(labels)
    return all(==(l), labels) && !isempty(l) ? l : nothing
end

function spannable_xy_labels(axs)
    nonempty_axs = filter(ax -> !isempty(ax.scene.plots), axs)
    xlabels = [ax.xlabel[] for ax in nonempty_axs]
    ylabels = [ax.ylabel[] for ax in nonempty_axs]
    
    # if layout has multiple columns, check if `xlabel` is spannable
    xlabel = size(axs, 2) > 1 ? unique_value(xlabels) : nothing

    # if layout has multiple rows, check if `ylabel` is spannable
    ylabel = size(axs, 1) > 1 ? unique_value(ylabels) : nothing

    return xlabel, ylabel
end

function replace_categorical(v::AbstractArray)
    labels = string.(levels(v))
    rg = axes(labels, 1)
    return levelcode.(v), (rg, labels)
end

replace_categorical(v::AbstractArray{<:Union{Number, Geometry}}) = (v, automatic)
replace_categorical(v::Any) = (v, automatic)

function draw!(figure, ts::ElementOrList)
    speclist = run_pipeline(ts)
    Nx, Ny, Ndodge = 1, 1, 1
    for spec in speclist
        Nx = max(Nx, rank(to_value(get(spec.options, :layout_x, Nx))))
        Ny = max(Ny, rank(to_value(get(spec.options, :layout_y, Ny))))
        # dodge may need to be done separately per each subplot
        Ndodge = max(Ndodge, rank(to_value(get(spec.options, :dodge, Ndodge))))
    end
    # What is a better placeholder here, in case some plots are missing?
    axs = Union{Axis, Nothing}[nothing for i in 1:Ny, j in 1:Nx]
    legend = Legend()
    level_dict = Dict{Symbol, Any}()
    encountered = Set()
    for trace in speclist
        pkeys, mapping, options = trace.pkeys, trace.mapping, trace.options
        P = plottype(trace)
        P isa Symbol && (P = getproperty(AbstractPlotting, P))
        args, kwargs = split(options)
        names, args = extract_names(args)
        attrs = Attributes(kwargs)
        apply_alpha_transparency!(attrs)
        x_pos = pop!(attrs, :layout_x, 1) |> to_value |> rank
        y_pos = pop!(attrs, :layout_y, 1) |> to_value |> rank
        subfig = figure[1, 1][y_pos, x_pos]
        args_and_ticks = map(replace_categorical, args)
        args, ticks = map(first, args_and_ticks), map(last, args_and_ticks)
        dodge = pop!(attrs, :dodge, nothing) |> to_value
        if !isnothing(dodge)
            width = pop!(attrs, :width, automatic) |> to_value
            arg, w = compute_dodge(first(args), rank(dodge), Ndodge, width=width)
            args = (arg, Base.tail(args)...)
            attrs.width = w
        end
        if isnothing(axs[y_pos, x_pos])
            ax, current = AbstractPlotting.plot(P, subfig, args...; attrs...)
            axs[y_pos, x_pos] = ax
        else
            ax = axs[y_pos, x_pos]
            current = AbstractPlotting.plot!(P, ax, args...; attrs...)
        end

        set_axis_labels!(ax, names)
        set_axis_ticks!(ax, ticks)

        for (k, v) in pairs(pkeys)
            name = get_name(v)
            val = strip_name(v)
            val isa CategoricalArray && get!(level_dict, k, levels(val))
            if k ∉ (:layout_x, :layout_y, :side, :dodge, :group) # position modifiers do not take part in the legend
                legendsection = add_entry!(legend, string(k); title=string(name))
                # here `val` will often be a NamedDimsArray, so we call `only` below
                entry = string(only(val))
                entry_traces = add_entry!(legendsection, entry)
                # make sure to write at most once on a legend entry per plot type
                if (P, k, entry) ∉ encountered
                    push!(entry_traces, current)
                    push!(encountered, (P, k, entry))
                end
            end
        end
    end

    for i in 1:Nx
        linkxaxes!(axs[:, i]...)
    end
    for i in 1:Ny
        linkyaxes!(axs[i, :]...)
    end
    hidexdecorations!.(axs[1:end-1, :], grid = false)
    hideydecorations!.(axs[:, 2:end], grid = false)

    if !isempty(legend.sections)
        try
            figure[1, 2] = create_legend(figure, legend)
        catch e
            @warn "Automated legend was not possible due to $e"
        end
    end
    
    layout_x_levels = get(level_dict, :layout_x, nothing)
    layout_y_levels = get(level_dict, :layout_y, nothing)
    
    # Check if axis labels are spannable (i.e., the same across all panels)
    spanned_xlab, spanned_ylab = spannable_xy_labels(axs)
    
    # faceting: hide x and y labels
    for ax in axs
        ax.xlabelvisible[] &= isnothing(spanned_xlab)
        ax.ylabelvisible[] &= isnothing(spanned_ylab)
    end

    add_facet_labels!(figure, axs, layout_x_levels;
        facetlayout = figure[1, 1], axis = :x, spanned_label = spanned_xlab,
        Nx = Nx, Ny = Ny)

    add_facet_labels!(figure, axs, layout_y_levels;
        facetlayout = figure[1, 1], axis = :y, spanned_label = spanned_ylab,
        Nx = Nx, Ny = Ny)

    return figure
end

function draw(s; kwargs...)
    figure = AbstractPlotting.Figure(; kwargs...)
    return draw!(figure, s)
end
draw(; kwargs...) = t -> draw(t; kwargs...)
