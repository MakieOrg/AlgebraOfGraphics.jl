"""
    SelectionPredicate

Internal structure representing a single predicate for the selection analysis.

# Fields
- `targets`: Single target (Int or Symbol) or multiple targets (Tuple) to extract from data
- `predicate`: Function to apply to the extracted target(s)
"""
struct SelectionPredicate
    targets::Union{Int, Symbol, Tuple{Vararg{Union{Int, Symbol}}}}
    predicate::Base.Callable
end

"""
    SelectionAnalysis

Internal structure representing a selection analysis transformation.

# Fields
- `predicates`: Tuple of SelectionPredicate objects
- `show_max`: Maximum number of groups to keep (highest ranking)
- `show_min`: Minimum number of groups to keep (lowest ranking)
- `skipmissing`: Whether to skip groups with missing predicate results
"""
struct SelectionAnalysis{P}
    predicates::P
    show_max::Union{Nothing, Int}
    show_min::Union{Nothing, Int}
    skipmissing::Bool
end

"""
    selection(predicate_specs...; show_max = nothing, show_min = nothing, skipmissing = false)

Filter data based on predicates applied to mapping slots. Supports four main modes:

1. **Bool mode**: Predicates return `Bool` → filter complete groups (keep or remove)
2. **Vector{Bool} mode**: Predicates return `Vector{Bool}` → filter individual rows
3. **Sortable mode**: Predicates return sortable values → rank groups and keep top/bottom N
4. **Vector{Sortable} mode**: Predicates return `Vector{<sortable>}` → rank individual data points across all groups and keep top/bottom N

# Arguments
- `predicate_specs...`: One or more predicate specifications of the form:
  - `target => predicate_func` where target is an Int (positional) or Symbol (named)
  - `(target1, target2, ...) => predicate_func` for multi-column predicates

# Keyword Arguments
- `show_max::Union{Nothing, Int}`: Keep the N groups with the largest ranking values
- `show_min::Union{Nothing, Int}`: Keep the N groups with the smallest ranking values
- `skipmissing::Bool`: If true, skip groups where predicate returns `missing` in Bool modes

# Mode Details

## Bool Mode
Each predicate returns a single `Bool` for each group. Groups are kept if all predicates
return `true`. Multiple predicates are combined with AND logic.

## Vector{Bool} Mode
Each predicate returns a `Vector{Bool}` with one element per row in the group. Rows are kept
if all predicates return `true` for that row.

## Sortable Mode
Each predicate returns a sortable value (Number, Date, String, etc.) for ranking groups.
Use `show_max` to keep the top N groups or `show_min` to keep the bottom N groups. Multiple
predicates create lexicographic ordering.

## Vector{Sortable} Mode
Each predicate returns a `Vector` of sortable values (Numbers, Dates, Strings, etc.) for ranking
individual data points across all groups. Use `show_max` to keep the top N data points or `show_min`
to keep the bottom N data points. Multiple predicates create lexicographic ordering.

# Examples

```julia
# Bool mode - Keep groups where maximum value > 10
data(...) * mapping(:time, :value, color = :group) * 
    selection(2 => v -> maximum(v) > 10) *
    visual(Lines)

# Vector{Bool} mode - Keep only positive values
data(...) * mapping(:x, :y) * 
    selection(2 => v -> v .> 0) *
    visual(Scatter)

# Sortable mode - Keep top 3 groups by maximum value
data(...) * mapping(:time, :value, color = :group) * 
    selection(2 => maximum, show_max = 3) *
    visual(Lines)

# Vector{Sortable} mode - Keep top 10 individual data points by value across all groups
data(...) * mapping(:x, :y) * 
    selection(2 => identity, show_max = 10) *
    visual(Scatter)

# Multiple predicates (AND-ed together)
data(...) * mapping(:x, :y, color = :group) * 
    selection(
        1 => v -> mean(v) > 5,
        2 => v -> std(v) < 2
    ) *
    visual(Scatter)

# Multi-column predicate
data(...) * mapping(:x, :y, :z, color = :group) * 
    selection((2, 3) => (y, z) -> cor(y, z) > 0.8) *
    visual(Scatter)

# Using named arguments (symbols)
data(...) * mapping(:x, :y, color = :group) * 
    selection(:color => grp -> first(grp) == "A") *
    visual(Scatter)

# Skip groups with missing predicate results
data(...) * mapping(:x, :y, color = :group) * 
    selection(2 => v -> mean(v) > 10, skipmissing = true) *
    visual(Scatter)
```

!!! note "Important Limitation"
    You can only filter on columns that are included in `mapping()`. Unlike `gghighlight` 
    in R, `selection` operates on `ProcessedLayer` objects which only contain the mapped 
    columns from the transformation pipeline.
    
    **There is no workaround** within the `selection` transformation. You cannot add extra 
    columns to `mapping()` just for filtering because they would be passed to the visual, 
    potentially causing errors or unwanted visual effects.
    
    **Alternative**: If you need to filter by unmapped columns, pre-filter the DataFrame:
    ```julia
    # Filter DataFrame before passing to data()
    filtered_df = filter(row -> row.quality > 0.5, df)
    
    data(filtered_df) * 
        mapping(:x, :y, color = :group) * 
        visual(Scatter)
    ```
"""
function selection(args...; show_max = nothing, show_min = nothing, skipmissing = false)
    # Validate that at most one of show_max or show_min is specified
    if show_max !== nothing && show_min !== nothing
        throw(ArgumentError("Cannot specify both `show_max` and `show_min`"))
    end
    
    # Validate show_max and show_min are positive integers
    if show_max !== nothing && show_max < 1
        throw(ArgumentError("`show_max` must be a positive integer, got $show_max"))
    end
    if show_min !== nothing && show_min < 1
        throw(ArgumentError("`show_min` must be a positive integer, got $show_min"))
    end
    
    # Parse predicate specifications
    predicates = SelectionPredicate[]
    
    for arg in args
        if !(arg isa Pair)
            throw(ArgumentError("Each argument to `selection` must be a Pair like `target => predicate`, got $(typeof(arg))"))
        end
        
        targets = first(arg)
        predicate = last(arg)
        
        # Validate targets
        if !(targets isa Union{Int, Symbol, Tuple})
            throw(ArgumentError("Target must be an Int, Symbol, or Tuple of Int/Symbol, got $(typeof(targets))"))
        end
        
        # If targets is a Tuple, validate all elements
        if targets isa Tuple
            for t in targets
                if !(t isa Union{Int, Symbol})
                    throw(ArgumentError("All elements in target tuple must be Int or Symbol, got $(typeof(t))"))
                end
            end
        end
        
        # Validate predicate is callable
        if !isa(predicate, Base.Callable)
            throw(ArgumentError("Predicate must be a callable function, got $(typeof(predicate))"))
        end
        
        push!(predicates, SelectionPredicate(targets, predicate))
    end
    
    if isempty(predicates)
        throw(ArgumentError("`selection` requires at least one predicate"))
    end
    
    return transformation(SelectionAnalysis(Tuple(predicates), show_max, show_min, skipmissing))
end

# Helper to extract target value(s) from positional and named arguments
function _extract_target(target::Int, positional, named, primary)
    N = length(positional)
    if target < 1 || target > N
        throw(ArgumentError("Target $target out of bounds for $N positional arguments"))
    end
    return positional[target]
end

function _extract_target(target::Symbol, positional, named, primary)
    # Check in named first, then primary
    if haskey(named, target)
        return named[target]
    elseif haskey(primary, target)
        return primary[target]
    else
        throw(ArgumentError("Target :$target not found in named or primary arguments"))
    end
end

function _extract_target(targets::Tuple, positional, named, primary)
    return tuple((_extract_target(t, positional, named, primary) for t in targets)...)
end

# Main processing function
function (s::SelectionAnalysis)(input::ProcessedLayer)
    # In ProcessedLayer, data is already grouped:
    # - primary contains one value per group (e.g., ["Adelie", "Chinstrap", "Gentoo"])
    # - positional and named contain nested arrays, one array per group
    
    # Determine number of groups from primary
    n_groups = if isempty(input.primary)
        # No grouping - single group
        1
    else
        # All primary entries should have the same length
        length(first(values(input.primary)))
    end
    
    # Apply all predicates to all groups
    predicate_results = map(s.predicates) do pred
        map(1:n_groups) do group_idx
            # Extract target values for this group
            if pred.targets isa Tuple
                # Multi-target predicate
                target_values = tuple((_extract_target(t, input.positional, input.named, input.primary)[group_idx] for t in pred.targets)...)
                return pred.predicate(target_values...)
            else
                # Single target predicate
                target_value = _extract_target(pred.targets, input.positional, input.named, input.primary)[group_idx]
                return pred.predicate(target_value)
            end
        end
    end
    
    # Detect mode based on predicate results
    first_result = first(predicate_results)
    result_eltype = eltype(first_result)
    
    # Determine mode
    mode = if result_eltype <: Bool || (s.skipmissing && result_eltype <: Union{Bool, Missing})
        :bool
    elseif result_eltype <: AbstractVector && eltype(result_eltype) <: Bool
        :vector_bool
    elseif result_eltype <: AbstractVector
        # Vector of sortable values
        if s.show_max === nothing && s.show_min === nothing
            throw(ArgumentError("Predicates returned Vector of sortable values but neither `show_max` nor `show_min` was specified"))
        end
        :vector_sortable
    elseif s.show_max !== nothing || s.show_min !== nothing
        # Scalar sortable values
        :sortable
    else
        # Scalar non-bool values without show_max/show_min
        throw(ArgumentError("Predicates returned sortable values but neither `show_max` nor `show_min` was specified"))
    end
    
    # Validate all predicates return the same mode
    for (i, result) in enumerate(predicate_results)
        et = eltype(result)
        if mode == :bool
            if !(et <: Bool || (s.skipmissing && et <: Union{Bool, Missing}))
                throw(ArgumentError("Predicate $(i) returned type $et but Bool mode was detected. All predicates must return Bool (or Union{Bool, Missing} with skipmissing=true)"))
            end
        elseif mode == :vector_bool
            if !(et <: AbstractVector && eltype(et) <: Bool)
                throw(ArgumentError("Predicate $(i) returned type $et but Vector{Bool} mode was detected. All predicates must return Vector{Bool}"))
            end
        elseif mode == :vector_sortable
            if !(et <: AbstractVector)
                throw(ArgumentError("Predicate $(i) returned type $et but Vector{Sortable} mode was detected. All predicates must return Vectors"))
            end
            # Check that the element type is sortable (not another vector)
            if eltype(et) <: AbstractArray
                throw(ArgumentError("Predicate $(i) returned nested array type $et. Expected Vector of sortable values"))
            end
        elseif mode == :sortable
            if et <: AbstractArray
                throw(ArgumentError("Predicate $(i) returned array type $et in sortable mode. Expected sortable values."))
            end
        end
    end
    
    # Filter based on mode
    if mode == :bool
        # Combine predicates with AND logic to determine which groups to keep
        keep_groups = map(1:n_groups) do group_idx
            results = [pred_result[group_idx] for pred_result in predicate_results]
            
            # Check for missing values
            if any(ismissing, results)
                if s.skipmissing
                    return false  # Skip groups with missing
                else
                    throw(ArgumentError("Predicate returned missing for group $group_idx but skipmissing=false"))
                end
            end
            
            # All must be true
            return all(results)
        end
        
        # Filter group indices
        kept_group_indices = findall(keep_groups)
        
        # Slice nested arrays to keep only selected groups
        new_positional = [col[kept_group_indices] for col in input.positional]
        
        new_named = Dictionary{Symbol, Any}()
        for (k, v) in pairs(input.named)
            insert!(new_named, k, v[kept_group_indices])
        end
        
        new_primary = Dictionary{Symbol, Any}()
        for (k, v) in pairs(input.primary)
            insert!(new_primary, k, v[kept_group_indices])
        end
        
    elseif mode == :vector_bool
        # Vector mode: filter rows within each group
        # First validate that all predicates return same-length vectors for each group
        for group_idx in 1:n_groups
            lengths = [length(pred_result[group_idx]) for pred_result in predicate_results]
            if !allequal(lengths)
                throw(ArgumentError("Vector predicates returned different lengths for group $group_idx: $lengths"))
            end
            # Also validate length matches group size
            group_size = length(input.positional[1][group_idx])
            if !allequal([lengths..., group_size])
                throw(ArgumentError("Vector predicate returned length $(first(lengths)) but group $group_idx has $group_size rows"))
            end
        end
        
        # Filter rows within each group
        new_positional = map(input.positional) do col
            map(1:n_groups) do group_idx
                # Get predicate results for this group
                pred_vecs = [pred_result[group_idx] for pred_result in predicate_results]
                # Element-wise AND to determine which rows to keep
                keep_rows = map(eachindex(pred_vecs[1])) do i
                    all(pv[i] for pv in pred_vecs)
                end
                # Filter the group's data
                return col[group_idx][keep_rows]
            end
        end
        
        new_named = Dictionary{Symbol, Any}()
        for (k, v) in pairs(input.named)
            filtered = map(1:n_groups) do group_idx
                pred_vecs = [pred_result[group_idx] for pred_result in predicate_results]
                keep_rows = map(eachindex(pred_vecs[1])) do i
                    all(pv[i] for pv in pred_vecs)
                end
                return v[group_idx][keep_rows]
            end
            insert!(new_named, k, filtered)
        end
        
        # Remove empty groups (groups with no rows remaining)
        # Identify non-empty groups
        non_empty_groups = findall(1:n_groups) do group_idx
            length(new_positional[1][group_idx]) > 0
        end
        
        # Filter to keep only non-empty groups
        new_positional = [col[non_empty_groups] for col in new_positional]
        
        new_named_filtered = Dictionary{Symbol, Any}()
        for (k, v) in pairs(new_named)
            insert!(new_named_filtered, k, v[non_empty_groups])
        end
        new_named = new_named_filtered
        
        new_primary = Dictionary{Symbol, Any}()
        for (k, v) in pairs(input.primary)
            insert!(new_primary, k, v[non_empty_groups])
        end
        
    elseif mode == :vector_sortable
        # Vector{Sortable} mode: rank individual data points across all groups and keep top/bottom N
        
        # First validate that all predicates return same-length vectors for each group
        for group_idx in 1:n_groups
            lengths = [length(pred_result[group_idx]) for pred_result in predicate_results]
            if !allequal(lengths)
                throw(ArgumentError("Vector predicates returned different lengths for group $group_idx: $lengths"))
            end
            # Also validate length matches group size
            group_size = length(input.positional[1][group_idx])
            if !allequal([lengths..., group_size])
                throw(ArgumentError("Vector predicate returned length $(first(lengths)) but group $group_idx has $group_size rows"))
            end
        end
        
        # Collect all data points with their rankings and (group_idx, row_idx) locations
        all_points = Tuple{Tuple, Int, Int}[]  # (ranking_tuple, group_idx, row_idx)
        
        for group_idx in 1:n_groups
            group_size = length(input.positional[1][group_idx])
            for row_idx in 1:group_size
                ranking_tuple = tuple((pred_result[group_idx][row_idx] for pred_result in predicate_results)...)
                push!(all_points, (ranking_tuple, group_idx, row_idx))
            end
        end
        
        # Sort all points by their ranking tuples
        if s.show_max !== nothing
            # Sort descending - we want the largest values first
            sorted_points = sort(all_points; rev=true, by=first, lt=(a, b) -> begin
                # Custom comparison that handles NaN (same as sortable mode)
                for (x, y) in zip(a, b)
                    if isnan(x) && isnan(y)
                        continue
                    end
                    if isnan(x)
                        return true
                    end
                    if isnan(y)
                        return false
                    end
                    if x != y
                        return x < y
                    end
                end
                return false
            end)
            n_keep = min(s.show_max, length(all_points))
            kept_points = sorted_points[1:n_keep]
        else  # s.show_min !== nothing
            # Sort ascending - we want the smallest values first
            sorted_points = sort(all_points; by=first, lt=(a, b) -> begin
                # Custom comparison that handles NaN (same as sortable mode)
                for (x, y) in zip(a, b)
                    if isnan(x) && isnan(y)
                        continue
                    end
                    if isnan(x)
                        return false
                    end
                    if isnan(y)
                        return true
                    end
                    if x != y
                        return x < y
                    end
                end
                return false
            end)
            n_keep = min(s.show_min, length(all_points))
            kept_points = sorted_points[1:n_keep]
        end
        
        # Build a dictionary of which rows to keep for each group
        rows_to_keep = Dict{Int, Vector{Int}}()
        for (_, group_idx, row_idx) in kept_points
            if !haskey(rows_to_keep, group_idx)
                rows_to_keep[group_idx] = Int[]
            end
            push!(rows_to_keep[group_idx], row_idx)
        end
        
        # Sort the row indices for each group to maintain order
        for (k, v) in rows_to_keep
            sort!(v)
        end
        
        # Filter data for each group
        new_positional = map(input.positional) do col
            map(1:n_groups) do group_idx
                if haskey(rows_to_keep, group_idx)
                    return col[group_idx][rows_to_keep[group_idx]]
                else
                    # No rows kept from this group, return empty array of same type
                    return similar(col[group_idx], 0)
                end
            end
        end
        
        new_named = Dictionary{Symbol, Any}()
        for (k, v) in pairs(input.named)
            filtered = map(1:n_groups) do group_idx
                if haskey(rows_to_keep, group_idx)
                    return v[group_idx][rows_to_keep[group_idx]]
                else
                    return similar(v[group_idx], 0)
                end
            end
            insert!(new_named, k, filtered)
        end
        
        # Remove empty groups (groups with no rows remaining)
        # Identify non-empty groups
        non_empty_groups = findall(1:n_groups) do group_idx
            length(new_positional[1][group_idx]) > 0
        end
        
        # Filter to keep only non-empty groups
        new_positional = [col[non_empty_groups] for col in new_positional]
        
        new_named_filtered = Dictionary{Symbol, Any}()
        for (k, v) in pairs(new_named)
            insert!(new_named_filtered, k, v[non_empty_groups])
        end
        new_named = new_named_filtered
        
        new_primary = Dictionary{Symbol, Any}()
        for (k, v) in pairs(input.primary)
            insert!(new_primary, k, v[non_empty_groups])
        end
        
    elseif mode == :sortable
        # Sortable mode: rank groups by predicate values and keep top/bottom N
        
        # Combine all predicate results into tuples for lexicographic sorting
        ranking_tuples = map(1:n_groups) do group_idx
            tuple((pred_result[group_idx] for pred_result in predicate_results)...)
        end
        
        # Sort groups by ranking tuples
        # For show_max: sort in descending order (largest first)
        # For show_min: sort in ascending order (smallest first)
        if s.show_max !== nothing
            # Sort descending - we want the largest values first
            # Handle NaN by treating them as smaller than any finite number
            sorted_indices = sortperm(ranking_tuples; rev=true, lt=(a, b) -> begin
                # Custom comparison that handles NaN
                # NaN should always be considered "smaller" (lower priority)
                for (x, y) in zip(a, b)
                    # If both are NaN, continue to next element
                    if isnan(x) && isnan(y)
                        continue
                    end
                    # NaN is always less than non-NaN
                    if isnan(x)
                        return true  # a < b (x is NaN, so a has lower priority)
                    end
                    if isnan(y)
                        return false  # a >= b (y is NaN, so b has lower priority)
                    end
                    # Neither is NaN, use regular comparison
                    if x != y
                        return x < y
                    end
                end
                return false  # All elements equal
            end)
            n_keep = min(s.show_max, n_groups)
            kept_group_indices = sort(sorted_indices[1:n_keep])
        else  # s.show_min !== nothing
            # Sort ascending - we want the smallest values first
            sorted_indices = sortperm(ranking_tuples; lt=(a, b) -> begin
                # Custom comparison that handles NaN
                # NaN should always be considered "larger" (lower priority)
                for (x, y) in zip(a, b)
                    # If both are NaN, continue to next element
                    if isnan(x) && isnan(y)
                        continue
                    end
                    # NaN is always greater than non-NaN
                    if isnan(x)
                        return false  # a >= b (x is NaN, so a has lower priority)
                    end
                    if isnan(y)
                        return true   # a < b (y is NaN, so b has lower priority)
                    end
                    # Neither is NaN, use regular comparison
                    if x != y
                        return x < y
                    end
                end
                return false  # All elements equal
            end)
            n_keep = min(s.show_min, n_groups)
            kept_group_indices = sort(sorted_indices[1:n_keep])
        end
        
        # Slice nested arrays to keep only selected groups
        new_positional = [col[kept_group_indices] for col in input.positional]
        
        new_named = Dictionary{Symbol, Any}()
        for (k, v) in pairs(input.named)
            insert!(new_named, k, v[kept_group_indices])
        end
        
        new_primary = Dictionary{Symbol, Any}()
        for (k, v) in pairs(input.primary)
            insert!(new_primary, k, v[kept_group_indices])
        end
    end
    
    # Return new ProcessedLayer with filtered data
    return ProcessedLayer(
        input;
        positional = new_positional,
        named = new_named,
        primary = new_primary,
    )
end
