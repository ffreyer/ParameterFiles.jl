# ParameterFiles.jl

This is a module to help generate many parameter files from a dictionary. It uses a a struct `Parameter(values[, dim=0])` to specify how values map to files. 

For example

```julia
param = Dict{Symbol, Any}(
    :T => Parameter([0.1, 0.2, 0.3], 1),
    :J => Parameter([0.1, 0.6], 2),
    :L => 4
)
save(ParameterContainer(param))
```

generates `6 = 2 * 3` parameter files, one for each combination of `[0.1, 0.2, 0.3]` and `[0.1, 0.6]`. An individual file can be loaded with

```julia
julia> sim_param = ParameterFiles.read_parameters("1.param")
Dict{Symbol,Any} with 5 entries:
  :T    => 0.1
  :J    => 0.1
  :L    => 4
```

where `1.param` to `6.param` are the default names. 
