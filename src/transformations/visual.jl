struct Visual
    plottype::PlotType
    attributes::NamedArguments
end
Visual(plottype::PlotType=Plot{plot}; kwargs...) = Visual(plottype, NamedArguments(kwargs))

function (v::Visual)(input::ProcessedLayer)
    plottype = Makie.plottype(v.plottype, input.plottype)
    attributes = merge(input.attributes, v.attributes)
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
mandatory_attributes(::Type{<:Union{BarPlot,Rangebars,Errorbars}}) = dictionary([:direction => :y])
mandatory_attributes(::Type{<:Union{Violin,RainClouds,BoxPlot}}) = dictionary([:orientation => :vertical])

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
                error("Aesthetic mapping lookup for $plottype failed with key $(repr(key)), could not find $(repr(attrkey)) in plot attributes. Consider adding `mandatory_attributes(::$plottype)` to define a default for $(repr(attrkey)).")
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

function aesthetic_mapping(T::Type{<:Plot})
    error("No aesthetic mapping defined yet for plot type $T. AlgebraOfGraphics can only use plot types if it is told which attributes and input arguments map to which aesthetics like color, markersize or linewidth for example.")
end

function aesthetic_mapping(::Type{Lines})
    dictionary([
        1 => AesX,
        2 => AesY,
        3 => AesZ,
        :color => AesColor,
        :linestyle => AesLineStyle,
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
        :width => :direction => dictionary([
            :y => AesDeltaX,
            :x => AesDeltaY,
        ]),
        :dodge => AesDodge,
        :stack => AesStack,
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
        :side => AesViolinSide,
        :dodge => AesDodge,
    ])
end

function aesthetic_mapping(::Type{Scatter})
    dictionary([
        1 => AesX,
        2 => AesY,
        3 => AesZ,
        :color => AesColor,
        :strokecolor => AesColor,
        :marker => AesMarker,
        :markersize => AesMarkerSize,
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

function aesthetic_mapping(::Type{RainClouds})
    dictionary([
        1 => :orientation => dictionary([
            :horizontal => AesY,
            :vertical => AesX,
        ]),
        2 => :orientation => dictionary([
            :horizontal => AesX,
            :vertical => AesY,
        ]),
        :color => AesColor,
    ])
end

function aesthetic_mapping(::Type{Heatmap})
    dictionary([
        1 => AesX,
        2 => AesY,
        3 => AesColor,
    ])
end

function aesthetic_mapping(::Type{LinesFill})
    dictionary([
        1 => AesX,
        2 => AesY,
        :lower => AesY,
        :upper => AesY,
        :color => AesColor,
    ])
end

function aesthetic_mapping(::Type{Rangebars})
    dictionary([
        1 => :direction => dictionary([
            :x => AesY,
            :y => AesX,
        ]),
        2 => :direction => dictionary([
            :x => AesX,
            :y => AesY,
        ]),
        3 => :direction => dictionary([
            :x => AesX,
            :y => AesY,
        ]),
        :color => AesColor,
    ])
end

function aesthetic_mapping(::Type{Errorbars})
    dictionary([
        1 => :direction => dictionary([
            :x => AesY,
            :y => AesX,
        ]),
        2 => :direction => dictionary([
            :x => AesDeltaX,
            :y => AesDeltaY,
        ]),
        3 => :direction => dictionary([
            :x => AesDeltaX,
            :y => AesDeltaY,
        ]),
        :color => AesColor,
    ])
end

function aesthetic_mapping(::Type{Makie.Text})
    dictionary([
        1 => AesX,
        2 => AesY,
        :text => AesText,
        :color => AesColor,
    ])
end

function aesthetic_mapping(::Type{BoxPlot})
    dictionary([
        1 => :orientation => dictionary([
            :horizontal => AesY,
            :vertical => AesX,
        ]),
        2 => :orientation => dictionary([
            :horizontal => AesX,
            :vertical => AesY,
        ]),
        :color => AesColor,
        :dodge => AesDodge,
    ])
end

function aesthetic_mapping(::Type{Contour})
    dictionary([
        1 => AesX,
        2 => AesY,
        3 => AesContourColor,
        :color => AesColor, # only categorical, for continous one would have to use 3
        :linestyle => AesLineStyle, # only categorical, for continous one would have to use 3
    ])
end

# if this wasn't set, a contour plot would be colored with a colormap according to positional arg 3, but we currently cannot handle that in the right way
mandatory_attributes(::Type{Contour}) = dictionary([:colormap => [Makie.current_default_theme()[:linecolor][]]])

function aesthetic_mapping(::Type{QQPlot})
    dictionary([
        1 => AesX,
        2 => AesY,
        :color => AesColor,
        :linestyle => AesLineStyle,
    ])
end

function aesthetic_mapping(::Type{QQNorm})
    dictionary([
        1 => AesY,
        :color => AesColor,
        :linestyle => AesLineStyle,
    ])
end

function aesthetic_mapping(::Type{Arrows})
    dictionary([
        1 => AesX,
        2 => AesY,
        3 => AesDeltaX,
        4 => AesDeltaY,
        :color => AesColor,
        :arrowhead => AesMarker,
    ])
end

function aesthetic_mapping(::Type{Choropleth})
    dictionary([
        1 => AesPlaceholder,
        :color => AesColor,
    ])
end

function aesthetic_mapping(::Type{Poly})
    dictionary([
        1 => AesPlaceholder,
        :color => AesColor,
    ])
end

function aesthetic_mapping(::Type{Surface})
    dictionary([
        1 => AesX,
        2 => AesY,
        3 => AesZ,
    ])
end
