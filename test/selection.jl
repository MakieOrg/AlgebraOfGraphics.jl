@testset "selection" begin
    # Test data
    df = (
        x = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        y = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100],
        group = ["a", "a", "a", "a", "a", "b", "b", "b", "b", "b"],
        subgroup = ["x", "x", "y", "y", "y", "x", "x", "x", "y", "y"],
    )

    @testset "constructor validation" begin
        # Valid constructors
        @test selection(1 => v -> mean(v) > 3) isa AlgebraOfGraphics.Layer
        @test selection(1 => v -> v .> 5) isa AlgebraOfGraphics.Layer
        @test selection(1 => maximum, show_max = 2) isa AlgebraOfGraphics.Layer
        @test selection(1 => identity, show_min = 3) isa AlgebraOfGraphics.Layer
        @test selection((1, 2) => (x, y) -> mean(x ./ y) > 0.5) isa AlgebraOfGraphics.Layer

        # Invalid: both show_max and show_min
        @test_throws ArgumentError selection(1 => maximum, show_max = 2, show_min = 3)
        
        # Invalid: non-positive show_max/show_min
        @test_throws ArgumentError selection(1 => maximum, show_max = 0)
        @test_throws ArgumentError selection(1 => maximum, show_max = -1)
        @test_throws ArgumentError selection(1 => maximum, show_min = 0)
        
        # Invalid: not a Pair
        @test_throws ArgumentError selection(1, v -> mean(v) > 3)
        
        # Invalid: target type
        @test_throws ArgumentError selection("bad" => v -> true)
        @test_throws ArgumentError selection((1, "bad") => (x, y) -> true)
        
        # Invalid: predicate not callable
        @test_throws ArgumentError selection(1 => 5)
        
        # Invalid: no predicates
        @test_throws ArgumentError selection()
    end

    @testset "Bool mode - single predicate" begin
        layer = data(df) * mapping(:x, :y, color = :group) * 
            selection(2 => v -> mean(v) > 50) *
            visual(Scatter)
        processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

        # Group "a" has mean y = 30, group "b" has mean y = 80
        # Only group "b" should remain
        @test processedlayer.primary == NamedArguments((color = ["b"],))
        
        x_vals, y_vals = processedlayer.positional
        @test length(x_vals) == 1  # Only one group
        @test x_vals[1] == [6, 7, 8, 9, 10]
        @test y_vals[1] == [60, 70, 80, 90, 100]
    end

    @testset "Bool mode - multiple predicates (AND logic)" begin
        layer = data(df) * mapping(:x, :y, color = :group, marker = :subgroup) * 
            selection(
                1 => v -> mean(v) > 3,     # Groups with mean x > 3
                2 => v -> maximum(v) < 90  # Groups with max y < 90
            ) *
            visual(Scatter)
        processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

        # Group a-x: mean x = 1.5, fails first predicate
        # Group a-y: mean x = 4, max y = 50, passes both
        # Group b-x: mean x = 7, max y = 80, passes both
        # Group b-y: mean x = 9.5, max y = 100, fails second predicate
        
        @test processedlayer.primary == NamedArguments((color = ["a", "b"], marker = ["y", "x"]))
    end

    @testset "Bool mode - using symbol targets" begin
        layer = data(df) * mapping(:x, :y, color = :group) * 
            selection(:color => ==("a")) *
            visual(Scatter)
        processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

        @test processedlayer.primary == NamedArguments((color = ["a"],))
        
        x_vals, y_vals = processedlayer.positional
        @test length(x_vals) == 1
        @test x_vals[1] == [1, 2, 3, 4, 5]
    end

    @testset "Vector{Bool} mode - single predicate" begin
        layer = data(df) * mapping(:x, :y, color = :group) * 
            selection(2 => v -> v .> 50) *
            visual(Scatter)
        processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

        # Rows with y > 50: indices 6-10
        # Group a: no rows match
        # Group b: all 5 rows match
        # Group a should be removed (empty group removal)
        @test processedlayer.primary == NamedArguments((color = ["b"],))
        
        x_vals, y_vals = processedlayer.positional
        @test length(x_vals) == 1
        @test x_vals[1] == [6, 7, 8, 9, 10]
        @test y_vals[1] == [60, 70, 80, 90, 100]
    end

    @testset "Vector{Bool} mode - multiple predicates" begin
        layer = data(df) * mapping(:x, :y, color = :group) * 
            selection(
                1 => v -> v .> 2,
                2 => v -> v .< 80
            ) *
            visual(Scatter)
        processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

        # Rows matching both: x > 2 AND y < 80
        # Group a: rows 3, 4, 5 (x: 3,4,5 y: 30,40,50)
        # Group b: rows 6, 7 (x: 6,7 y: 60,70)
        
        @test processedlayer.primary == NamedArguments((color = ["a", "b"],))
        
        x_vals, y_vals = processedlayer.positional
        @test x_vals[1] == [3, 4, 5]
        @test y_vals[1] == [30, 40, 50]
        @test x_vals[2] == [6, 7]
        @test y_vals[2] == [60, 70]
    end

    @testset "Vector{Bool} mode - empty group removal" begin
        layer = data(df) * mapping(:x, :y, color = :group) * 
            selection(2 => v -> v .> 100) *  # Impossible condition
            visual(Scatter)
        processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

        # All groups empty, should have no data
        @test processedlayer.primary == NamedArguments((color = String[],))
        
        x_vals, y_vals = processedlayer.positional
        @test length(x_vals) == 0
    end

    @testset "Sortable mode - show_max" begin
        layer = data(df) * mapping(:x, :y, color = :group) * 
            selection(2 => maximum, show_max = 1) *
            visual(Scatter)
        processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

        # Group a: max y = 50
        # Group b: max y = 100
        # Keep top 1 by max y -> group b
        @test processedlayer.primary == NamedArguments((color = ["b"],))
        
        x_vals, y_vals = processedlayer.positional
        @test x_vals[1] == [6, 7, 8, 9, 10]
        @test y_vals[1] == [60, 70, 80, 90, 100]
    end

    @testset "Sortable mode - show_min" begin
        layer = data(df) * mapping(:x, :y, color = :group) * 
            selection(1 => minimum, show_min = 1) *
            visual(Scatter)
        processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

        # Group a: min x = 1
        # Group b: min x = 6
        # Keep bottom 1 by min x -> group a
        @test processedlayer.primary == NamedArguments((color = ["a"],))
        
        x_vals, y_vals = processedlayer.positional
        @test x_vals[1] == [1, 2, 3, 4, 5]
    end

    @testset "Sortable mode - lexicographic ordering" begin
        # Create data with tied maximum values
        df2 = (
            x = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
            y = [100, 100, 100, 100, 100, 100, 50, 50, 50, 50, 50, 50],
            group = ["a", "a", "b", "b", "c", "c", "a", "a", "b", "b", "c", "c"],
        )

        layer = data(df2) * mapping(:x, :y, color = :group) * 
            selection(
                2 => maximum,  # Primary: all have max y = 100
                1 => minimum,  # Secondary: min x differs
                show_max = 2
            ) *
            visual(Scatter)
        processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

        # Group a: max y = 100, min x = 1
        # Group b: max y = 100, min x = 3
        # Group c: max y = 100, min x = 5
        # Sort by (max_y desc, min_x desc), take top 2
        # Result: group c (5), then group b (3)
        
        @test processedlayer.primary == NamedArguments((color = ["b", "c"],))
    end

    @testset "Sortable mode - multi-column predicate" begin
        layer = data(df) * mapping(:x, :y, color = :group) * 
            selection((1, 2) => (x, y) -> mean(y ./ x), show_max = 1) *
            visual(Scatter)
        processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

        # Group a: mean(y/x) = mean([10, 10, 10, 10, 10]) = 10
        # Group b: mean(y/x) = mean([10, 10, 10, 10, 10]) = 10
        # Tied, but one should be selected
        @test length(processedlayer.primary[:color]) == 1
    end

    @testset "sortable vector mode - show_max" begin
        layer = data(df) * mapping(:x, :y, color = :group) * 
            selection(2 => identity, show_max = 3) *
            visual(Scatter)
        processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

        # Top 3 individual y values: 100, 90, 80 (all from group b)
        # Group a should be removed (empty)
        @test processedlayer.primary == NamedArguments((color = ["b"],))
        
        x_vals, y_vals = processedlayer.positional
        @test x_vals[1] == [8, 9, 10]
        @test y_vals[1] == [80, 90, 100]
    end

    @testset "sortable vector mode - show_min" begin
        layer = data(df) * mapping(:x, :y, color = :group) * 
            selection(2 => identity, show_min = 3) *
            visual(Scatter)
        processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

        # Bottom 3 individual y values: 10, 20, 30 (all from group a)
        # Group b should be removed (empty)
        @test processedlayer.primary == NamedArguments((color = ["a"],))
        
        x_vals, y_vals = processedlayer.positional
        @test x_vals[1] == [1, 2, 3]
        @test y_vals[1] == [10, 20, 30]
    end

    @testset "sortable vector mode - multi-column predicate" begin
        layer = data(df) * mapping(:x, :y, color = :group) * 
            selection((2, 1) => (y, x) -> y ./ x, show_max = 4) *
            visual(Scatter)
        processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

        # Top 4 by y/x ratio:
        # All have ratio 10, so take first 4: indices 1,2,3,4
        # All from group a
        @test processedlayer.primary == NamedArguments((color = ["a"],))
        
        x_vals, y_vals = processedlayer.positional
        @test length(x_vals[1]) == 4
    end

    @testset "sortable vector mode - empty group removal" begin
        layer = data(df) * mapping(:x, :y, color = :group) * 
            selection(2 => identity, show_max = 5) *
            visual(Scatter)
        processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

        # Top 5 y values: 100, 90, 80, 70, 60 (all from group b)
        # Group a becomes empty and should be removed
        @test processedlayer.primary == NamedArguments((color = ["b"],))
    end

    @testset "Mode detection errors" begin
        # Sortable values without show_max/show_min
        layer = data(df) * mapping(:x, :y, color = :group) * 
            selection(2 => maximum)
        @test_throws ArgumentError AlgebraOfGraphics.ProcessedLayer(layer)

        # sortable vector without show_max/show_min
        layer = data(df) * mapping(:x, :y, color = :group) * 
            selection(2 => identity)
        @test_throws ArgumentError AlgebraOfGraphics.ProcessedLayer(layer)

        # Mixed predicate types (Bool and Sortable not supported yet)
        # This would require implementing mixed mode
    end

    @testset "Target validation errors" begin
        # Out of bounds positional target
        layer = data(df) * mapping(:x, :y, color = :group) * 
            selection(5 => v -> mean(v) > 0)
        @test_throws ArgumentError AlgebraOfGraphics.ProcessedLayer(layer)

        # Non-existent symbol target
        layer = data(df) * mapping(:x, :y, color = :group) * 
            selection(:nonexistent => v -> true)
        @test_throws ArgumentError AlgebraOfGraphics.ProcessedLayer(layer)
    end

    @testset "Vector length validation" begin
        # Predicate returns wrong length vector
        bad_predicate = v -> fill(true, length(v) + 1)  # Returns too many elements
        
        layer = data(df) * mapping(:x, :y, color = :group) * 
            selection(2 => bad_predicate)
        
        @test_throws ArgumentError AlgebraOfGraphics.ProcessedLayer(layer)
    end

    @testset "NaN handling in Sortable mode" begin
        df_nan = (
            x = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0],
            y = [NaN, 20.0, 30.0, 40.0, 50.0, 60.0],
            group = ["a", "a", "a", "b", "b", "b"],
        )

        # NaN should have lowest priority for both show_max and show_min
        layer = data(df_nan) * mapping(:x, :y, color = :group) * 
            selection(2 => maximum, show_max = 1) *
            visual(Scatter)
        processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

        # Group a: max = NaN (should be deprioritized)
        # Group b: max = 60
        # Group b should win
        @test processedlayer.primary == NamedArguments((color = ["b"],))
    end

    @testset "No grouping columns" begin
        # Selection should work with no categorical groupings
        df_simple = (x = [1, 2, 3, 4, 5], y = [10, 20, 30, 40, 50])
        
        layer = data(df_simple) * mapping(:x, :y) * 
            selection(2 => v -> v .> 25) *
            visual(Scatter)
        processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

        x_vals, y_vals = processedlayer.positional
        @test x_vals[1] == [3, 4, 5]
        @test y_vals[1] == [30, 40, 50]
    end

    @testset "Integration with real penguins data" begin
        df_penguins = AlgebraOfGraphics.penguins()
        
        # Bool mode: filter to species with mean body mass > 4000
        layer = data(df_penguins) * 
            mapping(:bill_length_mm, :body_mass_g, color = :species) * 
            selection(2 => v -> mean(skipmissing(v)) > 4000) *
            visual(Scatter)
        processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)
        
        # Only Gentoo should remain
        @test "Gentoo" in processedlayer.primary[:color]
        @test !("Adelie" in processedlayer.primary[:color])
        @test !("Chinstrap" in processedlayer.primary[:color])
        
        # Vector{Bool} mode: filter individual penguins
        layer = data(df_penguins) * 
            mapping(:bill_length_mm, :body_mass_g, color = :species) * 
            selection(2 => v -> v .> 4500) *
            visual(Scatter)
        processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)
        
        # Should have fewer rows than original
        total_rows = sum(length(v) for v in processedlayer.positional[1])
        @test total_rows < length(first(df_penguins))
        @test total_rows > 0
        
        # Sortable mode: top 2 species by max body mass
        layer = data(df_penguins) * 
            mapping(:bill_length_mm, :body_mass_g, color = :species) * 
            selection(2 => maximum ∘ skipmissing, show_max = 2) *
            visual(Scatter)
        processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)
        
        # Should have exactly 2 species
        @test length(processedlayer.primary[:color]) == 2
    end
end
