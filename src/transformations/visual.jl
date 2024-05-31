struct Visual
    plottype::PlotType
    attributes::NamedArguments
end
Visual(plottype::PlotType=Plot{plot}; kwargs...) = Visual(plottype, NamedArguments(kwargs))

function (v::Visual)(input::ProcessedLayer)
    plottype = Makie.plottype(v.plottype, input.plottype)
    default_attrs = mandatory_attributes(plottype)
    attributes = merge(default_attrs, input.attributes, v.attributes)

    return ProcessedLayer(input; plottype, attributes)
end

# In the future, consider switching from `visual(Plot{T})` to `visual(T)`.
visual(plottype::PlotType=Plot{plot}; kwargs...) = transformation(Visual(plottype; kwargs...))

# For backward compatibility, still allow `visual(Any)`.
@deprecate visual(::Type{Any}; kwargs...) visual(; kwargs...)

# Whenever a plot type's `aesthetic_mapping` depends on the value of some attribute,
# it has to be ensured that this value is present. We could also grab it from the theme
# but it seems very weird that someone would want a theme where all barplots switch from
# vertical to horizontal mode. So it is more straightforward to simply fix any attributes
# which are required to some known value, unless overridden by the user. Usually, that should
# be the same value that the plot type also sets in its default theme.
mandatory_attributes(T) = NamedArguments()
mandatory_attributes(::Type{BarPlot}) = dictionary([:direction => :y])
mandatory_attributes(::Type{Violin}) = dictionary([:orientation => :vertical])

# this function needs to be defined for any plot type that should work with AoG, because it tells
# AoG how its positional arguments can be understood in terms of the dimensions of the plot for
# which AoG computes scales
# The default assumption of x, y, [z] does not hold for many plot objects
function aesthetic_mapping end

aesthetic_mapping(p::ProcessedLayer) = aesthetic_mapping(p.plottype, p.attributes)

function aesthetic_mapping(plottype, attributes)::AestheticMapping
    mapping = aesthetic_mapping(plottype)
    for (key, value) in pairs(mapping)
        if value isa Pair
            attrkey, dict = value
            if !haskey(attributes, attrkey)
                error("Aesthetic mapping lookup for $plottype failed with key $(repr(key)), could not find $(repr(attrkey)) in plot attributes")
            end
            attrvalue = attributes[attrkey]
            if !haskey(dict, attrvalue)
                error("Aesthetic mapping lookup for $plottype failed with key $(repr(key)), no entry for attribute $(repr(attrkey)) with value $(attrvalue). Existing variants are $(dict)")
            end
            aes = dict[attrvalue]
            mapping[key] = aes
        end
    end
    return mapping
end

function aesthetic_mapping(::Type{Lines})
    dictionary([
        1 => AesX,
        2 => AesY,
        :color => AesColor
    ])
end


function aesthetic_mapping(::Type{BarPlot})
    dictionary([
        1 => :direction => dictionary([
            :y => AesX,
            :x => AesY,
        ]),
        2 => :direction => dictionary([
            :y => AesY,
            :x => AesX,
        ]),
        :color => AesColor,
    ])
end

function aesthetic_mapping(::Type{Violin})
    dictionary([
        1 => :orientation => dictionary([
            :horizontal => AesX,
            :vertical => AesY,
        ]),
        2 => :orientation => dictionary([
            :horizontal => AesY,
            :vertical => AesX,
        ]),
        :color => AesColor,
    ])
end

function aesthetic_mapping(::Type{Scatter})
    dictionary([
        1 => AesX,
        2 => AesY,
        :color => AesColor,
        :strokecolor => AesColor,
        :marker => AesMarker,
    ])
end

function aesthetic_mapping(::Type{HLines})
    dictionary([
        1 => AesY,
        :color => AesColor,
    ])
end

function aesthetic_mapping(::Type{VLines})
    dictionary([
        1 => AesX,
        :color => AesColor,
    ])
end
