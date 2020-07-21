function apply_alpha_transparency!(attrs::Attributes)
    # manually implement alpha values
    c = get(attrs, :color, Observable(:black))
    alpha = get(attrs, :alpha, Observable(1))
    attrs[:color] = c[] isa Union{Tuple, AbstractArray} ? c : lift(tuple, c, alpha)
end

function set_axis_labels!(ax, names)
    for (nm, prop) in zip(names, (:xlabel, :ylabel, :zlabel))
        s = string(nm)
        if hasproperty(ax, prop) && getproperty(ax, prop)[] == " "
            getproperty(ax, prop)[] = s
        end
    end
end

function layoutplot!(scene, layout, ts::ElementOrList)
    facetlayout = layout[1, 1] = GridLayout()
    speclist = run_pipeline(ts)
    Nx, Ny = 1, 1
    for spec in speclist
        Nx = max(Nx, rank(to_value(get(spec.options, :layout_x, Nx))))
        Ny = max(Ny, rank(to_value(get(spec.options, :layout_y, Ny))))
    end
    axs = facetlayout[1:Ny, 1:Nx] = [LAxis(scene) for i in 1:Ny, j in 1:Nx]
    for i in 1:Nx
        linkxaxes!(axs[:, i]...)
    end
    for i in 1:Ny
        linkyaxes!(axs[i, :]...)
    end
    hidexdecorations!.(axs[1:end-1, :], grid = false)
    hideydecorations!.(axs[:, 2:end], grid = false)

    legend = Legend()
    level_dict = Dict{Symbol, Any}()
    encountered = Set()
    for trace in speclist
        pkeys, style, options = trace.pkeys, trace.style, trace.options
        P = plottype(trace)
        P isa Symbol && (P = getproperty(AbstractPlotting, P))
        args, kwargs = split(options)
        names, args = extract_names(args)
        attrs = Attributes(kwargs)
        apply_alpha_transparency!(attrs)
        x_pos = pop!(attrs, :layout_x, 1) |> to_value |> rank
        y_pos = pop!(attrs, :layout_y, 1) |> to_value |> rank
        current = AbstractPlotting.plot!(axs[y_pos, x_pos], P, attrs, args...)
        set_axis_labels!(axs[y_pos, x_pos], names)
        for (k, v) in pairs(pkeys)
            name = get_name(v)
            val = strip_name(v)
            val isa CategoricalArray && get!(level_dict, k, levels(val))
            if k ∉ (:layout_x, :layout_y)
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
    if !isempty(legend.sections)
        try
            layout[1, 2] = create_legend(scene, legend)
        catch e
            @warn "Automated legend was not possible due to $e"
        end
    end
    
    layout_x_levels = get(level_dict, :layout_x, nothing)
    layout_y_levels = get(level_dict, :layout_y, nothing)
    
    # Check if axis labels are spannable (i.e. the same across all panels)
    spanned_xlab, spanned_ylab = spannable_xy_labels(axs)
    
    # faceting: hide x and y labels
    for i in 1:length(facetlayout.content)
        ax = facetlayout.content[i].content
        ax.xlabelvisible[] &= isnothing(spanned_xlab)
        ax.ylabelvisible[] &= isnothing(spanned_ylab)
    end

    if !isnothing(layout_x_levels)
        # Facet labels
        lxl = string.(layout_x_levels)
        @assert length(lxl) == Nx
        for i in 1:Nx
            text = LText(scene, lxl[i])
            facetlayout[1, i, Top()] = LRect(
                scene, color = RGBAf0(0, 0, 0, 0.2), strokevisible=false
            ) 
            facetlayout[1, i, Top()] = text
        end
    
        # Shared xlabel
        group_bottom_protrusion = lift(
            (xs...) -> maximum(y -> y.bottom, xs),
            (MakieLayout.protrusionsobservable(ax) for ax in axs[end, :])...
        )
    
        padx = Node(10.0)
        toppad = @lift($group_bottom_protrusion + $padx)
    
        xlabel = LText(scene,
                       spanned_xlab,
                       padding = @lift((0, 0, 0, $toppad)))
        facetlayout[end, :, Bottom()] = xlabel
    end
    
    if !isnothing(layout_y_levels)
        # Facet labels
        lyl = string.(layout_y_levels)
        @assert length(lyl) == Ny
        for i in 1:Ny
            text = LText(scene, lyl[i], rotation = -π/2)
            facetlayout[i, end, Right()] = LRect(
                scene, color = RGBAf0(0, 0, 0, 0.2), strokevisible=false
            ) 
            facetlayout[i, end, Right()] = text
        end
    
        # Shared ylabel
        group_left_protrusion = lift(
            (xs...) -> maximum(y -> y.left, xs),
            (MakieLayout.protrusionsobservable(ax) for ax in axs[:, 1])...
        )
    
        pady = Node(10.0)
        rightpad = @lift($group_left_protrusion + $pady)
    
        ylabel = LText(scene,
                       spanned_ylab,
                       padding = @lift((0, $rightpad, 0, 0)),
                       rotation = π/2) 
        facetlayout[:, 1, Left()] = ylabel
    end    

    return scene
end

# Return the unique value of the collection if it exists, `nothing` otherwise.
function unique_value(labels)
    l = first(labels)
    return all(==(l), labels) ? l : nothing
end

function spannable_xy_labels(axs)
    nonempty_axs = filter(ax -> length(ax.scene.plots) > 0, axs)
    xlabels = [ax.xlabel[] for ax in nonempty_axs]
    ylabels = [ax.ylabel[] for ax in nonempty_axs]
    
    # if layout has multiple columns, check if `xlabel` is spannable
    xlabel = size(axs, 2) > 1 ? unique_value(xlabels) : nothing

    # if layout has multiple rows, check if `ylabel` is spannable
    ylabel = size(axs, 1) > 1 ? unique_value(ylabels) : nothing

    return xlabel, ylabel
end

function layoutplot(s; kwargs...)
    scene, layout = MakieLayout.layoutscene(; kwargs...)
    return layoutplot!(scene, layout, s)
end
layoutplot(; kwargs...) = t -> layoutplot(t; kwargs...)

draw(args...; kwargs...) = layoutplot(args...; kwargs...)
