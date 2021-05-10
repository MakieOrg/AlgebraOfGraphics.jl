function MakieLayout.Legend(fg::FigureGrid)
	colorbar = _Colorbar_(fg)
    legend = _Legend_(fg)
    if !isnothing(colorbar)
		Colorbar(fg.figure[:, end + 1]; colorbar.label, colorbar.limits)
	end
	if !isnothing(legend)
		Legend(fg.figure[:, end + 1], legend...)
	end
end

function getlabeledcolorbar(scales, labels)
	for key in (:color, 3)
		label, scale = get(labels, key, nothing), get(scales, key, nothing)
		scale isa ContinuousScale && return Labeled(label, scale)
	end
	return
end

function _Colorbar_(fg::FigureGrid)
    grid = fg.grid
	labeledcolorbar = getlabeledcolorbar(first(grid).scales, first(grid).labels)
	isnothing(labeledcolorbar) && return
	label, colorscale = getlabel(labeledcolorbar), getvalue(labeledcolorbar)
	limits = colorscale.extrema
    return (; label, limits)
end

function _Legend_(fg::FigureGrid)
	grid = fg.grid
	entries = Iterators.flatten(ae.entries for ae in grid)

	# assume all subplots have same scales, to be changed to support free scales
    named_scales = first(grid).scales.named
    named_labels = copy(first(grid).labels.named)

    # remove keywords that don't support legends
	for key in [:row, :col, :layout, :stack, :dodge, :group]
		pop!(named_labels, key, nothing)
	end
	for (key, val) in named_scales
		val isa ContinuousScale && pop!(named_labels, key, nothing)
	end

    # if no legend-worthy keyword remains return nothing
    isempty(named_labels) && return nothing

	attr_dict = mapreduce((a, b) -> mergewith!(union, a, b), entries) do entry
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

#Notes

# TODO: correctly handle composite plot types (now fall back to poly)
# TODO: check that all scales for the same label agree on the data
# TODO: make legend updateable?
# TODO: allow custom attributes in legend elements?
# TODO: avoid recomputing `Entries`
