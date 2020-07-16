function add_entry!(names, values, entry; default)
    i = findfirst(==(entry), names)
    if isnothing(i)
        push!(names, entry)
        push!(values, default)
        i = lastindex(names)
    end
    return values[i]
end

struct LegendSection
    title::String
    names::Vector{String}
    plots::Vector{Vector{AbstractPlot}}
end
LegendSection(title::String="") = LegendSection(title, String[], Vector{AbstractPlot}[])

# Add an empty trace list with name `entry` to the legend section
function add_entry!(legendsection::LegendSection, entry::String)
    names, plots = legendsection.names, legendsection.plots
    return add_entry!(names, plots, entry; default=AbstractPlot[])
end

struct Legend
    names::Vector{String}
    sections::Vector{LegendSection}
end
Legend() = Legend(String[], LegendSection[])

# Add an empty section with name `entry` and title `title` to the legend
function add_entry!(legend::Legend, entry::String; title::String="")
    names, sections = legend.names, legend.sections
    return add_entry!(names, sections, entry; default=LegendSection(title))
end

function create_legend(scene, legend::Legend)
    sections = legend.sections
    MakieLayout.LLegend(
        scene,
        getproperty.(sections, :plots),
        getproperty.(sections, :names),
        getproperty.(sections, :title)
    )
end

function adjust_color(c, alpha)
    to_value(c) isa Union{Tuple, AbstractArray} ? c : map(tuple, c, alpha)
end

function set_defaults!(attrs::Attributes)
    # manually implement alpha values
    col = get(attrs, :color, Observable(:black))
    alpha = get(attrs, :alpha, Observable(1))
    attrs[:color] = adjust_color(col, alpha)
end

function set_names!(ax, names)
    for (nm, prop) in zip(names, (:xlabel, :ylabel, :zlabel))
        s = string(nm)
        if !isempty(s)
            getproperty(ax, prop)[] = s
        end
    end
end

function somestring(s, t)
    s = string(s)
    isempty(s) ? string(t) : s
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
    for trace in speclist
        pkeys, style, options = trace.pkeys, trace.style, trace.options
        P = plottype(trace)
        P isa Symbol && (P = getproperty(AbstractPlotting, P))
        args, kwargs = split(options)
        names, args = extract_names(args)
        attrs = Attributes(kwargs)
        set_defaults!(attrs)
        x_pos = pop!(attrs, :layout_x, 1) |> to_value |> rank
        y_pos = pop!(attrs, :layout_y, 1) |> to_value |> rank
        current = AbstractPlotting.plot!(axs[y_pos, x_pos], P, attrs, args...)
        set_names!(axs[y_pos, x_pos], names)
        for (k, v) in pairs(pkeys)
            name = somestring(get_name(v), k)
            val = strip_name(v)
            # here v will often be a NamedDimsArray, so we call `only` below
            val isa CategoricalArray && get!(level_dict, k, levels(val))
            if k ∉ (:layout_x, :layout_y)
                legendsection = add_entry!(legend, string(k); title=name)
                entry_traces = add_entry!(legendsection, string(only(val)))
                push!(entry_traces, current)
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
    
    ax1 = axs[end,1]
    
    layout_x_levels = get(level_dict, :layout_x, nothing)
    layout_y_levels = get(level_dict, :layout_y, nothing)

    # faceting: hide x and y labels
    for i in 1:length(facetlayout.content)
        ax = facetlayout.content[i].content
        ax.xlabelvisible[] &= isnothing(layout_x_levels)
        ax.ylabelvisible[] &= isnothing(layout_y_levels)
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
                       ax1.xlabel[],
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
                       ax1.ylabel[],
                       padding = @lift((0, $rightpad, 0, 0)),
                       rotation = π/2) 
        facetlayout[:, 1, Left()] = ylabel
    end    

    return scene
end

function layoutplot(s; kwargs...)
    scene, layout = MakieLayout.layoutscene(; kwargs...)
    return layoutplot!(scene, layout, s)
end
layoutplot(; kwargs...) = t -> layoutplot(t; kwargs...)

draw(args...; kwargs...) = layoutplot(args...; kwargs...)

