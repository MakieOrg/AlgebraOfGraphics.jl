using CairoMakie
import DelimitedFiles
using Test
using Statistics
using PixelMatch
using PNGFiles
using Base64

function reftest(f::Function, name::String, update::Bool = get(ENV, "UPDATE_REFIMAGES", "false") == "true")
    @info name
    fig = with_theme(f, size = (400, 400))
    path = joinpath(@__DIR__, "reference_tests")
    mkpath(path)
    ref_path = joinpath(path, name * " ref.png")
    rec_path = joinpath(path, name * " rec.png")
    diff_path = joinpath(path, name * " diff.png")

    save(rec_path, fig; px_per_unit = 1, backend = CairoMakie)

    @testset "$name" begin        
        reference_exists = isfile(ref_path)

        if !reference_exists
            if isinteractive()
                @info "Creating missing reference image: $ref_path"
                cp(rec_path, ref_path; force=true)
            else
                @test reference_exists
            end
        else
            # Load both images
            img_ref = PNGFiles.load(ref_path)
            img_rec = PNGFiles.load(rec_path)
            
            # Compare images using PixelMatch
            num_pixels_diff, diff_image = PixelMatch.pixelmatch(img_ref, img_rec)
            
            if num_pixels_diff > 0
                # Save diff image
                PNGFiles.save(diff_path, diff_image)
                
                # Print paths for inspection
                println("Reference test failed for: $name")
                println("  Reference: $ref_path")
                println("  Recorded:  $rec_path")
                println("  Diff:      $diff_path")
                println("  Pixels different: $num_pixels_diff")
                
                # In interactive mode, offer to replace reference
                if isinteractive()
                    if update
                        println("update = true, updating reference image")
                        cp(rec_path, ref_path; force=true)
                    else
                        # Display images in VS Code if available
                        if Base.displayable(MIME("juliavscode/html"))
                            show_html_differ(; name, num_pixels_diff, ref_path, rec_path, diff_path)
                        end
                        print("Replace reference with recorded image? (y/n): ")
                        response = readline()
                        if lowercase(strip(response)) == "y"
                            cp(rec_path, ref_path; force=true)
                            println("Reference image updated.")
                        else
                            @test false
                        end
                    end
                else
                    @test false
                end
            else
                # Images match
                @test true
            end
        end
    end
    return fig # so running a block interactively shows the image
end

function show_html_differ(; name, num_pixels_diff, ref_path, rec_path, diff_path)
    # Convert images to base64 for HTML display
    ref_b64 = Base64.base64encode(read(ref_path))
    rec_b64 = Base64.base64encode(read(rec_path))
    diff_b64 = Base64.base64encode(read(diff_path))
    
    html_content = """
    <div style="font-family: Arial, sans-serif; padding: 20px;">
        <h3>Image Comparison Failed: $(name)</h3>
        <p><strong>Pixels different:</strong> $num_pixels_diff</p>
        
        <div style="margin: 10px 0;">
            <button onclick="toggleRecordedReference()" id="btn-toggle" style="margin-right: 10px; padding: 8px 16px; background: #6c757d; color: white; border: none; border-radius: 4px; cursor: pointer;">Show Recorded</button>
            <button onclick="showDiff()" id="btn-diff" style="padding: 8px 16px; background: #dc3545; color: white; border: none; border-radius: 4px; cursor: pointer;">Diff</button>
        </div>
        
        <div style="border: 2px solid #ddd; border-radius: 8px; padding: 10px; background: #f8f9fa; max-width: 100%; overflow: auto;">
            <img id="img-recorded" src="data:image/png;base64,$rec_b64" style="max-width: 100%; height: auto; display: none;" />
            <img id="img-reference" src="data:image/png;base64,$ref_b64" style="max-width: 100%; height: auto; display: none;" />
            <img id="img-diff" src="data:image/png;base64,$diff_b64" style="max-width: 100%; height: auto; display: block;" />
        </div>
        
        <script>
            let showingRecorded = true;
            let showingDiff = true;
            
            function updateToggleButton() {
                if (showingDiff) {
                    document.getElementById('btn-toggle').textContent = showingRecorded ? 'Show Recorded' : 'Show Reference';
                } else {
                    document.getElementById('btn-toggle').textContent = showingRecorded ? 'Showing Recorded' : 'Showing Reference';
                }
            }
            
            function toggleRecordedReference() {
                if (showingDiff) {
                    // If showing diff, switch back to current recorded/reference view without toggling
                    document.getElementById('img-diff').style.display = 'none';
                    document.getElementById('btn-diff').style.background = '#6c757d';
                    showingDiff = false;
                    
                    // Show current state (don't toggle)
                    if (showingRecorded) {
                        document.getElementById('img-recorded').style.display = 'block';
                        document.getElementById('img-reference').style.display = 'none';
                    } else {
                        document.getElementById('img-recorded').style.display = 'none';
                        document.getElementById('img-reference').style.display = 'block';
                    }
                } else {
                    // Normal toggle between recorded and reference
                    if (showingRecorded) {
                        // Switch to reference
                        document.getElementById('img-recorded').style.display = 'none';
                        document.getElementById('img-reference').style.display = 'block';
                        showingRecorded = false;
                    } else {
                        // Switch to recorded
                        document.getElementById('img-reference').style.display = 'none';
                        document.getElementById('img-recorded').style.display = 'block';
                        showingRecorded = true;
                    }
                }
                
                updateToggleButton();
                document.getElementById('btn-toggle').style.background = '#007acc';
            }
            
            function showDiff() {
                // Hide recorded/reference images
                document.getElementById('img-recorded').style.display = 'none';
                document.getElementById('img-reference').style.display = 'none';
                document.getElementById('img-diff').style.display = 'block';
                
                // Update button styles
                document.getElementById('btn-toggle').style.background = '#6c757d';
                document.getElementById('btn-diff').style.background = '#dc3545';
                showingDiff = true;
            }
            
            // Initialize button text
            updateToggleButton();
        </script>
    </div>
    """
    
    display(MIME("juliavscode/html"), html_content)
end
