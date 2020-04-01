#=
Conservative 7-color palette from Points of view: Color blindness, Bang Wong - Nature Methods
https://www.nature.com/articles/nmeth.1618?WT.ec_id=NMETH-201106
=#

const wong_colors = [
    RGB(230/255, 159/255, 0/255),
    RGB(86/255, 180/255, 233/255),
    RGB(0/255, 158/255, 115/255),
    RGB(240/255, 228/255, 66/255),
    RGB(0/255, 114/255, 178/255),
    RGB(213/255, 94/255, 0/255),
    RGB(204/255, 121/255, 167/255),
]

const default_palettes = Dict(
    :color     => wong_colors,
    :marker    => [:circle, :xcross, :utriangle, :diamond, :dtriangle, :star8, :pentagon, :rect],
    :linestyle => [nothing, :dash, :dot, :dashdot, :dashdotdot],
    :side      => [:left, :right]
)

