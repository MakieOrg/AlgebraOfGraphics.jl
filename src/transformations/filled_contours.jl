Base.@kwdef struct FilledContoursAnalysis
    bands::Union{Nothing, Int}
    levels::Union{Nothing, Vector{Float64}}
    kwargs::Dict{Symbol, Any}
end

function (c::FilledContoursAnalysis)(input::ProcessedLayer)
    z_limits = AlgebraOfGraphics.nested_extrema_finite(input.positional[3])
    _levels(limits, bands::Int, levels::Nothing)::Vector{Float64} = collect(range(limits..., length = bands + 1))
    _levels(limits, bands::Nothing, levels::Vector{Float64}) = levels
    _levels(limits, bands, levels) = error("You must specify only either `bands` or `levels`")
    lvls = _levels(z_limits, c.bands, c.levels)


    xs = Vector{Float64}[]
    ys = Vector{Float64}[]
    ids = Vector{Verbatim{Int}}[]
    subids = Vector{Verbatim{Int}}[]
    bins = Bin[]

    named = map(empty, input.named)
    primary = map(empty, input.primary)

    for idx in CartesianIndices(shape(input))
        _x, _y, _z = slice(input.positional, idx)
        nslice = slice(input.named, idx)
        primslice = slice(input.primary, idx)

        (x, y, z) = Makie.convert_arguments(Contourf, _x, _y, _z)
        _xs, _ys, _ids, _subids, _bins = calculate_pregrouped_poly_columns(x, y, z, lvls)

        for (_x, _y, _id, _subid, bin) in zip(_xs, _ys, _ids, _subids, _bins)
            push!(xs, _x)
            push!(ys, _y)
            push!(ids, _id)
            push!(subids, _subid)
            push!(bins, bin)
            for key in keys(named)
                push!(named[key], nslice[key])
            end
            for key in keys(primary)
                push!(primary[key], primslice[key])
            end
        end
    end

    insert!(primary, :color, bins)

    return ProcessedLayer(;
        plottype = LongPoly,
        positional = Any[xs, ys, ids, subids],
        primary,
    )

end

"""
    filled_contours(; bands=automatic, levels=automatic)

Create filled contours over the grid spanned over x and y by args 1 and 2 in the `mapping`,
with height values z passed via arg 3. 

You can pass either the number of bands to `bands` or pass a vector of levels (the boundaries
of the bands) to `levels`, but not both.
The number of bands when `levels` is passed is `length(levels) - 1`.
The levels are calculated across the whole z data if the number of `bands` is specified.
If neither levels nor bands are specified, the default is `bands = 10`.

Note that `visual(Contourf)` does not work with AlgebraOfGraphics since version 0.7,
because the internal binning it does is not compatible with the scale system.
"""
function filled_contours(; bands = automatic, levels = automatic, kwargs...)
    if bands === automatic && levels === automatic
        bands = 10
    end
    bands = bands === automatic ? nothing : bands
    levels = levels === automatic ? nothing : levels
    return transformation(FilledContoursAnalysis(; bands, levels, kwargs = Dict(kwargs)))
end

# copied and adjusted from Makie

function calculate_pregrouped_poly_columns(xs, ys, zs, levels)
    @assert issorted(levels)

    lows = levels[1:(end - 1)]
    highs = levels[2:end]

    # zs needs to be transposed to match rest of makie
    isos = Isoband.isobands(xs, ys, zs', lows, highs)

    xs_out = Vector{Float64}[]
    ys_out = Vector{Float64}[]
    poly_ids = Vector{Verbatim{Int}}[]
    poly_subids = Vector{Verbatim{Int}}[]
    bins = Bin[]

    current_id = 1
    for (level_index, group) in enumerate(isos)
        _xs = Float64[]
        _ys = Float64[]
        _poly_ids = Verbatim{Int}[]
        _poly_subids = Verbatim{Int}[]

        points = Point2f.(group.x, group.y)
        polygroups = _group_polys(points, group.id)
        for polygroup in polygroups
            for (i, ring) in enumerate(polygroup)
                append!(_xs, first.(ring))
                append!(_ys, last.(ring))
                append!(_poly_ids, fill(verbatim(current_id), length(ring)))
                append!(_poly_subids, fill(verbatim(i), length(ring)))
            end
            current_id += 1
        end

        push!(xs_out, _xs)
        push!(ys_out, _ys)
        push!(poly_ids, _poly_ids)
        push!(poly_subids, _poly_subids)
        bin = Bin((levels[level_index], levels[level_index + 1]), (level_index == 1, true))
        push!(bins, bin)
    end
    return xs_out, ys_out, poly_ids, poly_subids, bins
end


# copied from Makie

function _group_polys(points, ids)
    polys = [points[ids .== i] for i in unique(ids)]

    polys_lastdouble = [push!(p, first(p)) for p in polys]

    # this matrix stores whether poly i is contained in j
    # because the marching squares algorithm won't give us any
    # intersecting or overlapping polys, it should be enough to
    # check if a single point is contained, saving some computation time
    containment_matrix = [
        p1 != p2 &&
            PolygonOps.inpolygon(first(p1), p2) == 1
            for p1 in polys_lastdouble, p2 in polys_lastdouble
    ]

    unclassified_polyindices = collect(1:size(containment_matrix, 1))

    # each group has first an outer polygon, and then its holes
    # TODO: don't specifically type this 2f0?
    groups = Vector{Vector{Point2f}}[]

    # a dict that maps index in `polys` to index in `groups` for outer polys
    outerindex_groupdict = Dict{Int, Int}()

    # all polys have to be classified
    while !isempty(unclassified_polyindices)
        to_keep = ones(Bool, length(unclassified_polyindices))

        # go over unclassifieds and find outer polygons in the remaining containment matrix
        for (ii, i) in enumerate(unclassified_polyindices)
            # an outer polygon is not inside any other polygon of the matrix
            if sum(containment_matrix[ii, :]) == 0
                # an outer polygon
                # println(i, " is an outer polygon")
                push!(groups, [polys_lastdouble[i]])
                outerindex_groupdict[i] = length(groups)
                # delete this poly from further rounds
                to_keep[ii] = false
            end
        end

        # go over unclassifieds and find hole polygons
        for (ii, i) in enumerate(unclassified_polyindices)
            # the hole polygons can only be in one polygon from the current group
            # if they are in more than one, they are "inner outer" or inner hole polys
            # and will be handled in one of the following passes
            if sum(containment_matrix[ii, :]) == 1
                outerpolyindex_of_unclassified = findfirst(containment_matrix[ii, :])
                outerpolyindex = unclassified_polyindices[outerpolyindex_of_unclassified]
                # a hole
                # println(i, " is an inner polygon of ", outerpolyindex)
                groupindex = outerindex_groupdict[outerpolyindex]
                push!(groups[groupindex], polys_lastdouble[i])
                # delete this poly from further rounds
                to_keep[ii] = false
            end
        end

        unclassified_polyindices = unclassified_polyindices[to_keep]
        containment_matrix = containment_matrix[to_keep, to_keep]
    end
    return groups
end
