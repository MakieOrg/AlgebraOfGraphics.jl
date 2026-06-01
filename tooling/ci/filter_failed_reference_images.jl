# Keep only the images belonging to failed reference tests so the CI artifact stays
# small. The reference test harness writes `<name> diff.png` only when a test fails;
# this keeps each `<name> diff.png` together with its `<name> ref.png` and
# `<name> rec.png` and deletes every other png.

function filter_failed_reference_images(dir::String)
    diff_suffix = " diff.png"
    bases = Set{String}()
    for file in readdir(dir)
        endswith(file, diff_suffix) || continue
        push!(bases, file[1:(end - length(diff_suffix))])
    end

    for base in bases
        println("Keeping failed reference images for: ", base)
    end

    keep = Set(joinpath(dir, base * s) for base in bases for s in (" diff.png", " ref.png", " rec.png"))
    for file in readdir(dir)
        endswith(file, ".png") || continue
        path = joinpath(dir, file)
        if !(path in keep)
            rm(path)
        end
    end

    println("Filtering complete. Kept $(length(bases)) failed reference test(s).")
end

filter_failed_reference_images(joinpath(@__DIR__, "..", "..", "test", "reference_tests"))
