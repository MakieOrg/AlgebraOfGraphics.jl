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
- `max_n`: Maximum number of groups to keep (highest ranking)
- `min_n`: Minimum number of groups to keep (lowest ranking)
- `skipmissing`: Whether to skip groups with missing predicate results
"""
struct SelectionAnalysis{P}
    predicates::P
    max_n::Union{Nothing, Int}
    min_n::Union{Nothing, Int}
    skipmissing::Bool
end

"""
    selection(predicate_specs...; max_n = nothing, min_n = nothing, skipmissing = false)

Filter data based on predicates applied to mapping slots. Supports three main modes:

1. **Bool mode**: Predicates return `Bool` → filter complete groups (keep or remove)
2. **Vector{Bool} mode**: Predicates return `Vector{Bool}` → filter individual rows
3. **Sortable mode**: Predicates return sortable values → rank groups and keep top/bottom N

# Arguments
- `predicate_specs...`: One or more predicate specifications of the form:
  - `target => predicate_func` where target is an Int (positional) or Symbol (named)
  - `(target1, target2, ...) => predicate_func` for multi-column predicates

# Keyword Arguments
- `max_n::Union{Nothing, Int}`: Keep the N groups with the largest ranking values
- `min_n::Union{Nothing, Int}`: Keep the N groups with the smallest ranking values
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
Use `max_n` to keep the top N groups or `min_n` to keep the bottom N groups. Multiple
predicates create lexicographic ordering.

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
    selection(2 => maximum, max_n = 3) *
    visual(Lines)

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
"""
function selection(args...; max_n = nothing, min_n = nothing, skipmissing = false)
    # Validate that at most one of max_n or min_n is specified
    if max_n !== nothing && min_n !== nothing
        throw(ArgumentError("Cannot specify both `max_n` and `min_n`"))
    end
    
    # Validate max_n and min_n are positive integers
    if max_n !== nothing && max_n < 1
        throw(ArgumentError("`max_n` must be a positive integer, got $max_n"))
    end
    if min_n !== nothing && min_n < 1
        throw(ArgumentError("`min_n` must be a positive integer, got $min_n"))
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
    
    return transformation(SelectionAnalysis(Tuple(predicates), max_n, min_n, skipmissing))
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
    mode = if s.max_n !== nothing || s.min_n !== nothing
        :sortable
    elseif result_eltype <: Bool || (s.skipmissing && result_eltype <: Union{Bool, Missing})
        :bool
    elseif result_eltype <: AbstractVector && eltype(result_eltype) <: Bool
        :vector_bool
    else
        # Check if it's a sortable type (not an array)
        if result_eltype <: AbstractArray
            throw(ArgumentError("Predicate returned array type $result_eltype which is not supported. Expected Bool, Vector{Bool}, or a sortable value."))
        end
        # If max_n/min_n not specified but we have sortable values, that's an error
        throw(ArgumentError("Predicates returned sortable values but neither `max_n` nor `min_n` was specified"))
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
        
        # In Vector{Bool} mode, primary values remain unchanged
        # They are just group labels that don't change when filtering rows within groups
        new_primary = input.primary
        
    elseif mode == :sortable
        throw(ErrorException("Sortable mode not yet implemented (Phase 4)"))
    end
    
    # Return new ProcessedLayer with filtered data
    return ProcessedLayer(
        input;
        positional = new_positional,
        named = new_named,
        primary = new_primary,
    )
end
