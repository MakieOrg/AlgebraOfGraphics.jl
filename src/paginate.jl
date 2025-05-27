# Dispatcher type for `draw` usage.
struct Pagination
    each::Vector{Matrix{AxisSpecEntries}}
    layout::Union{Nothing, Int}
    row::Union{Nothing, Int}
    col::Union{Nothing, Int}
end

Base.length(p::Pagination) = length(p.each)

function Base.show(io::IO, p::Pagination)
    _info = filter(
        !isnothing ∘ last,
        [key => getfield(p, key) for key in (:layout, :row, :col)]
    )
    _info_str = isempty(_info) ? "no limits set" :
        join(("$key = $value" for (key, value) in _info), ", ")
    n = length(p)
    entry_str = n == 1 ? "1 entry" : "$n entries"
    print(io, "Pagination with $entry_str ($_info_str)")
end

"""
    draw(p::Pagination; kws...)

Draw each element of `Pagination` `p` and return a `Vector{FigureGrid}`.
Keywords `kws` are passed to the underlying `draw` calls.
"""
function draw(p::Pagination; axis = (;), figure = (;), facet = (;), legend = (;), colorbar = (;))
    axis = _kwdict(axis, :axis)
    figure = _kwdict(figure, :figure)
    facet = _kwdict(facet, :facet)
    legend = _kwdict(legend, :legend)
    colorbar = _kwdict(colorbar, :colorbar)
    _draw.(p.each; axis, figure, facet, legend, colorbar)
end

"""
    draw(p::Pagination, i::Int; kws...)

Draw the ith element of `Pagination` `p` and return a `FigureGrid`.
Keywords `kws` are passed to the underlying `draw` call.

You can retrieve the number of elements using `length(p)`.
"""
function draw(p::Pagination, i::Int; axis = (;), figure = (;), facet = (;), legend = (;), colorbar = (;))
    if i ∉ 1:length(p)
        throw(ArgumentError("Invalid index $i for Pagination with $(length(p)) entries."))
    end
    axis = _kwdict(axis, :axis)
    figure = _kwdict(figure, :figure)
    facet = _kwdict(facet, :facet)
    legend = _kwdict(legend, :legend)
    colorbar = _kwdict(colorbar, :colorbar)
    _draw(p.each[i]; axis, figure, facet, legend, colorbar)
end

function draw(p::Pagination, ::Scales, args...; kws...)
    throw(ArgumentError("Calling `draw` with a `Pagination` object and `scales` is invalid. The `scales` must be passed to `paginate` already and are baked into the `Pagination` output."))
end

"""
    paginate(l, sc = scales(); layout=nothing, row=nothing, col=nothing)

Paginate `l`, the `Layer` or `Layers` object created by an `AlgebraOfGraphics` spec, to create a
`Pagination` object.

!!! info
    The pages are created by internally starting with one big facet plot first which includes all
    the input data, and then splitting it into pages. All scales are fit to the full data,
    not just the data that is visible on a given page, so a color legend, for example, will
    show all the categories and not just the ones that happen to be visible on the current page.
    This behavior changed with version 0.9 - before, each page had separately fit scales.
    The old behavior had the drawback that palettes were not guaranteed to be consistent across pages,
    for example, the same category could have different colors on two separate pages.

The `Pagination` object can be passed to `draw` which will return a `Vector{FigureGrid}`
rather than a single figure.

The keywords that limit the number of subplots on each page are the same that are used
to specify facets in `mapping`:
  - `layout`: Maximum number of subplots in a wrapped linear layout.
  - `row`: Maximum number of rows in a 2D layout.
  - `col`: Maximum number of columns in a 2D layout.

## Example

```julia
d = data((
    x = rand(1000),
    y = rand(1000),
    group1 = rand(string.('a':'i'), 1000),
    group2 = rand(string.('j':'r'), 1000),
))

layer_1 = d * mapping(:x, :y, layout = :group1) * visual(Scatter)
paginated_1 = paginate(layer_1, layout = 4)
figuregrids = draw(paginated_1)

layer_2 = d * mapping(:x, :y, row = :group1, col = :group2) * visual(Scatter)
paginated_2 = paginate(layer_2, row = 4, col = 3)
figuregrid = draw(paginated_2, 1) # draw only the first grid
```
"""
function paginate(
        l::Union{Layer, Layers},
        sc = scales();
        layout::Union{Int,Nothing} = nothing,
        row::Union{Int,Nothing} = nothing,
        col::Union{Int,Nothing} = nothing,
    )
    axgrid = compute_axes_grid(l, sc)
    pag_axgrids = paginate_axes_grid(axgrid; layout, row, col)
    return Pagination(pag_axgrids, layout, row, col)
end

# The idea of pagination is to take the matrix of AxisSpecEntries and split it up into multiple smaller ones
# which are then presented to the rest of the pipeline as usual.
# The scales will be fit using all available data, though, which means that colors etc. across facets stay
# correct and are not computed anew with each page.
# One slight complication is that the Layout, Row and Col scales must be sliced into shorter ones for each
# facet that uses them, so that the facet decoration logic doesn't attempt to label 12 columns where only 3 per facet exist.
function paginate_axes_grid(agrid::Matrix{AxisSpecEntries}; layout = nothing, row = nothing, col = nothing)
    representative = agrid[1, 1]
    catscales = representative.categoricalscales
    if layout !== nothing
        scale = extract_single(AesLayout, catscales)
        scale === nothing && error("Pagination by `layout` failed because no corresponding scale is present in the spec.")
        
        paginated = Matrix{AxisSpecEntries}[]
        dvalues = datavalues(scale)
        pvalues = plotvalues(scale)
        dlabels = datalabels(scale)

        for groupindices in Iterators.partition(eachindex(dvalues, pvalues), layout)
            # TODO: should the original wrap style be preserved? may depend on type, not everything will work
            wrapped_positions = apply_palette(wrapped(), 1:length(groupindices))

            props = scale.props
            sliced_scale = CategoricalScale(
                dvalues[groupindices],
                wrapped_positions,
                scale.label,
                (Accessors.@set props.categories = dvalues[groupindices] .=> dlabels[groupindices]),
                scale.aes,
            )
            new_catscales = merge_in_scale(catscales, AesLayout, sliced_scale)

            mat_dimensions = (maximum(first.(wrapped_positions)), maximum(last.(wrapped_positions)))
            mat = [AxisSpecEntries(
                    AxisSpec(representative.axis.type, Tuple(idx), NamedArguments()),
                    Entry[],
                    new_catscales,
                    representative.continuousscales,
                    ProcessedLayer[]
                )
                for idx in CartesianIndices(mat_dimensions)]

            for (paginated_position, original_position) in zip(wrapped_positions, pvalues[groupindices])
                original = agrid[original_position...]
                mat[paginated_position...] = AxisSpecEntries(
                    AxisSpec(original.axis.type, paginated_position, original.axis.attributes),
                    original.entries,
                    new_catscales,
                    original.continuousscales,
                    original.processedlayers,
                )
            end
            push!(paginated, mat)
        end
    elseif row !== nothing || col !== nothing
        rowscale = extract_single(AesRow, catscales)
        rowscale === nothing && row !== nothing  && error("Pagination by `row` failed because no corresponding scale is present in the spec.")
        colscale = extract_single(AesCol, catscales)
        colscale === nothing && col !== nothing && error("Pagination by `col` failed because no corresponding scale is present in the spec.")

        paginated = Matrix{AxisSpecEntries}[]
        row_dvalues = rowscale === nothing ? nothing : datalabels(rowscale)
        row_pvalues = rowscale === nothing ? nothing : plotvalues(rowscale)
        col_dvalues = colscale === nothing ? nothing : datalabels(colscale)
        col_pvalues = colscale === nothing ? nothing : plotvalues(colscale)

        for row_groupindices in Iterators.partition(1:size(agrid, 1), something(row, size(agrid, 1)))
            for col_groupindices in Iterators.partition(1:size(agrid, 2), something(col, size(agrid, 2)))
                new_catscales = catscales
                if row !== nothing
                    props = rowscale.props
                    sliced_rowscale = CategoricalScale(
                        row_dvalues[invperm(row_pvalues)][row_groupindices],
                        1:length(row_dvalues),
                        rowscale.label,
                        (Accessors.@set props.categories = nothing), # categories are already baked in and should not be reapplied later
                        rowscale.aes,
                    )
                    new_catscales = merge_in_scale(new_catscales, AesRow, sliced_rowscale)
                end
                if col !== nothing
                    props = colscale.props
                    sliced_colscale = CategoricalScale(
                        col_dvalues[invperm(col_pvalues)][col_groupindices],
                        1:length(col_dvalues),
                        colscale.label,
                        (Accessors.@set props.categories = nothing), # categories are already baked in and should not be reapplied later
                        colscale.aes,
                    )
                    new_catscales = merge_in_scale(new_catscales, AesCol, sliced_colscale)
                end
                agrid_slice = agrid[row_groupindices, col_groupindices]
                pag_agrid = map(CartesianIndices(agrid_slice)) do paginated_idx
                    original = agrid_slice[paginated_idx]
                    AxisSpecEntries(
                        AxisSpec(original.axis.type, Tuple(paginated_idx), original.axis.attributes),
                        original.entries,
                        new_catscales,
                        original.continuousscales,
                        original.processedlayers,
                    )
                end
                push!(paginated, pag_agrid)
            end
        end
    else
        return [agrid]
    end
    return paginated
end

function merge_in_scale(m::MultiAesScaleDict, key::Type{<:Aesthetic}, scale)
    new_m = typeof(m)()
    @assert haskey(m, key)
    for aes in keys(m)
        if aes === key
            insert!(new_m, key, Dictionary{Union{Nothing,Symbol},CategoricalScale}([only(keys(m[key]))], [scale]))
        else
            insert!(new_m, aes, m[aes])
        end
    end
    return new_m
end

function modified_scale(cat::CategoricalScale, newdata, newplot)
    CategoricalScale(
        newdata,
        newplot,
        cat.label,
        cat.props,
        cat.aes,
    )
end
