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
    legend = remove_duplicates(legend)
    sections = legend.sections
    MakieLayout.LLegend(
        scene,
        getproperty.(sections, :plots),
        getproperty.(sections, :names),
        # LLegend needs `nothing` to remove the space for a missing title
        [t == " " ? nothing : t for t in getproperty.(sections, :title)]
    )
end

function remove_duplicates(legend)
    sections = legend.sections
    titles = getproperty.(sections, :title)
    # check if there are duplicate titles
    unique_inds = unique_indices(titles; keep = " ")
    has_duplicates = length(unique_inds) < length(titles)
    # if so: remove duplicates, generate new names
    if has_duplicates
        sections_new = sections[unique_inds]
        names_new = legend.names[unique_inds]
        return Legend(names_new, sections_new)
    else
        return legend
    end
end

function unique_indices(x; keep)
    first_inds = indexin(x, x)
    inds_keep = findall(==(keep), x)
    sort!(union!(inds_keep, first_inds))
end
