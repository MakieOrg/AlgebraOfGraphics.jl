using CairoMakie
import ImageInTerminal
import DelimitedFiles
using Test
using Statistics

rgbaf_convert(x::AbstractMatrix{<:Makie.RGB}) = convert(Matrix{RGBAf}, x)
rgbaf_convert(x::AbstractMatrix{<:Makie.RGBA}) = convert(Matrix{RGBAf}, x)

function compare_images(a::AbstractMatrix{<:Union{Makie.RGB,Makie.RGBA}}, b::AbstractMatrix{<:Union{Makie.RGB,Makie.RGBA}})

    # convert always to RGBA, as at some point CairoMakie output changed due to PNGFiles
    a = rgbaf_convert(a)
    b = rgbaf_convert(b)

    if size(a) != size(b)
        return Inf, nothing
    end

    approx_tile_size_px = 30

    range_dim1 = round.(Int, range(0, size(a, 1), length = ceil(Int, size(a, 1) / approx_tile_size_px)))
    range_dim2 = round.(Int, range(0, size(a, 2), length = ceil(Int, size(a, 2) / approx_tile_size_px)))

    boundary_iter(boundaries) = zip(boundaries[1:end-1] .+ 1, boundaries[2:end])

    _norm(rgb1::RGBf, rgb2::RGBf) = sqrt(sum(((rgb1.r - rgb2.r)^2, (rgb1.g - rgb2.g)^2, (rgb1.b - rgb2.b)^2)))
    _norm(rgba1::RGBAf, rgba2::RGBAf) = sqrt(sum(((rgba1.r - rgba2.r)^2, (rgba1.g - rgba2.g)^2, (rgba1.b - rgba2.b)^2, (rgba1.alpha - rgba2.alpha)^2)))

    # compute the difference score as the maximum of the mean squared differences over the color
    # values of tiles over the image. using tiles is a simple way to increase the local sensitivity
    # without directly going to pixel-based comparison
    # it also makes the scores more comparable between reference images of different sizes, because the same
    # local differences would be normed to different mean scores if the images have different numbers of pixels
    return maximum(Iterators.product(boundary_iter(range_dim1), boundary_iter(range_dim2))) do ((mi1, ma1), (mi2, ma2))
        m = @views mean(_norm.(a[mi1:ma1, mi2:ma2], b[mi1:ma1, mi2:ma2]))
        return m, (mi1:ma1, mi2:ma2)
    end
end

function reftest(f::Function, name::String, update::Bool = get(ENV, "UPDATE_REFIMAGES", "false") == "true"; threshold = 0.05)
    @info name
    CairoMakie.activate!(px_per_unit = 1)
    fig = with_theme(f, size = (400, 400))
    path = joinpath(@__DIR__, "reference_tests")
    mkpath(path)
    refpath = joinpath(path, name * " ref.png")
    recpath = joinpath(path, name * " rec.png")
    
    save(recpath, fig)

    @testset "$name" begin
        ref_exists = isfile(refpath)
        @test ref_exists

        if ref_exists
            ref = Makie.FileIO.load(refpath)
            rec = Makie.FileIO.load(recpath)
            maxscore, tile = compare_images(ref, rec)
            if !update
                    @test size(ref) == size(rec)
                    @test maxscore <= threshold
            end
            if maxscore > threshold && maxscore != Inf
                @info "\"$name\" score $maxscore at $(tile)"
                maxsize = (200, 200) # in github actions you can always maximize your screen later but a tiny view doesn't help
                @info "Reference"
                ImageInTerminal.imshow(ref, maxsize)
                println()
                @info "Recording"
                ImageInTerminal.imshow(rec, maxsize)
                println()
            end
            if maxscore > threshold
                if update
                    rm(refpath)
                    cp(recpath, refpath)
                    @info "Updated reference image \"$name\""
                else
                    @info "Set ENV[\"UPDATE_REFIMAGES\"] = true to update or pass `true` to a specific `reftest function`"
                end
            end
        else
            cp(recpath, refpath)
            @info "New reference image \"$name\""
        end
    end
    return fig # so running a block interactively shows the image
end

@testset "Reference tests" begin
    include("reference_tests.jl")
end