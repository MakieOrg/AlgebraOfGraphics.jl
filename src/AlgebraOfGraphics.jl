module AlgebraOfGraphics

using Tables: columns, getcolumn, columnnames, AbstractColumns, Tables
using CategoricalArrays: categorical, cut, levelcode, refs, levels, CategoricalArray
using Observables: AbstractObservable, Observable, to_value
using NamedDims: NamedDimsArray, dimnames
using StructArrays: GroupPerm, refine_perm!, uniquesorted, fieldarrays, StructArray
using KernelDensity: kde
using StatsBase: fit, Histogram, weights, AbstractWeights, normalize, sturges, histrange
import GLM, Loess

using AbstractPlotting: Point2f0,
                        Attributes,
                        AbstractPlot,
                        Node,
                        automatic,
                        Automatic,
                        lift,
                        @lift,
                        RGBAf0,
                        AbstractPlotting

using AbstractPlotting.MakieLayout: LAxis,
                                    LText,
                                    LRect,
                                    GridLayout,
                                    linkxaxes!,
                                    linkyaxes!,
                                    hidexdecorations!,
                                    hideydecorations!,
                                    Top,
                                    Bottom,
                                    Left,
                                    Right,
                                    MakieLayout

export data, dims, draw, spec, style
export categorical, cut

include("algebraic_list.jl")
include("utils.jl")
include("context.jl")
include("specs.jl")
include("scales.jl")
include("analysis/analysis.jl")
include("analysis/smooth.jl")
include("analysis/density.jl")
include("analysis/frequency.jl")
include("analysis/histogram.jl")
include("legend.jl")
include("dodge.jl")
include("colorbar.jl")
include("draw.jl")

end # module
