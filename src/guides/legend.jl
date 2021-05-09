# ------------------------------------------------
# -------------------- Legend --------------------
# ------------------------------------------------

MakieLayout.Legend(figpos, aog::Union{Layer,Layers}) = 
    Legend(figpos, Entries(aog))
    
function MakieLayout.Legend(figpos, entries::Entries)
    legend = _Legend_(entries)
    isnothing(legend) && return
    
    if figpos isa FigureGrid
        figpos_new = figpos.figure[:,end + 1]
    else
        figpos_new = figpos
    end

    Legend(figpos_new, legend...)
end

function _Legend_(entries)
    named_scales = entries.scales.named
    named_labels = copy(entries.labels.named)

    # remove keywords that don't support legends
	for key in [:row, :col, :layout, :stack, :dodge, :group]
		pop!(named_labels, key, nothing)
	end
	for (key, val) in named_scales
		val isa ContinuousScale && pop!(named_labels, key, nothing)
	end

    # if no legend-worthy keyword remains return nothing
    isempty(named_labels) && return nothing

	attr_dict = mapreduce((a, b) -> mergewith!(union, a, b), entries.entries) do entry
		# FIXME: this should probably use the rescaled values
		defaultplottype = AbstractPlotting.plottype(entry.mappings.positional...)
		plottype = AbstractPlotting.plottype(entry.plottype, defaultplottype)
		attrs = keys(entry.mappings.named)
		return LittleDict{PlotFunc, Vector{Symbol}}(plottype => collect(attrs))
    end

	titles = unique!(collect(String, values(named_labels)))
	# empty strings create difficulties with the layout
	nonemptytitles = map(t -> isempty(t) ? " " : t, titles)

	labels_list = Vector{String}[]
	elements_list = Vector{Vector{LegendElement}}[]

	for title in titles
		label_attrs = [key for (key, val) in named_labels if val == title]
		first_scale = named_scales[first(label_attrs)]
		labels = map(string, first_scale.data)
		plottypes = [P => attrs ∩ label_attrs for (P, attrs) in pairs(attr_dict)]
		filter!(t -> !isempty(last(t)), plottypes)
		elements = map(eachindex(first_scale.data)) do idx
			local elements = LegendElement[]
			for (P, attrs) in plottypes
				options = [attr => named_scales[attr].plot[idx] for attr in attrs]
				append!(elements, legend_elements(P; options...))
			end
			return elements
		end
		push!(labels_list, labels)
		push!(elements_list, elements)
	end
	return elements_list, labels_list, nonemptytitles
end

# ------------------------------------------------
# ----- LegendElements with more defaults --------
# ------------------------------------------------

function from_default_theme(attr)
    theme = default_styles()
    return get(theme, attr) do
        AbstractPlotting.current_default_theme()[attr]
    end
end

line_element(;
             color=from_default_theme(:color),
             linestyle=from_default_theme(:linestyle),
             linewidth=from_default_theme(:linewidth),
             kwargs...) = 
    LineElement(; color, linestyle, linewidth, kwargs...)

marker_element(;
               color=from_default_theme(:color),
               marker=from_default_theme(:marker),
               strokecolor=from_default_theme(:strokecolor),
               markerpoints=[Point2f0(0.5, 0.5)],
               kwargs...) =
    MarkerElement( ; color, marker, strokecolor, markerpoints, kwargs...)

poly_element(;
             color=from_default_theme(:color),
             strokecolor=:transparent,
             kwargs...) = 
    PolyElement(; color, strokecolor, kwargs...)

legend_elements(::Type{Scatter}; kwargs...) = [marker_element(; kwargs...)]
legend_elements(::Type{Lines}; kwargs...) = [line_element(; kwargs...)]
legend_elements(::Type{Contour}; kwargs...) = [line_element(; kwargs...)]

function legend_elements(::Type{LinesFill}; color=from_default_theme(:color), fillalpha=0.15, kwargs...)
	meshcolor = to_color((color, fillalpha))
	return [poly_element(; color=meshcolor, kwargs...), line_element(; color, kwargs...)]
end

legend_elements(::Any; linewidth=0, strokecolor=:transparent, kwargs...) =
	[poly_element(; linewidth, kwargs...)]

#Notes

# TODO: correctly handle composite plot types (now fall back to poly)
# TODO: check that all scales for the same label agree on the data
# TODO: make legend updateable?
# TODO: allow custom attributes in legend elements?
# TODO: avoid recomputing `Entries`

# WIP colorbar implementation

# function _legend(P, attribute, scale::ContinuousScale, title)
#     extrema = scale.extrema
#     # @unpack f, extrema = scale
#     n_ticks = 4
    
#     ticks = MakieLayout.locateticks(extrema..., n_ticks)

#     label_kw = [(label = L(tick), kw = KW(attribute, tick)) for tick in ticks]
    
#     (; title, P, label_kw)
# end