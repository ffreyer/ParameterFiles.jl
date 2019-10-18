# TODO
# do transformations
# e.g. :T => something  -->  :Ts => [something]

"""
    Parameter(value[, dim=0, type_tag=typeof(value)])

Generates a Parameter with some `value` acting on some `dim`.

- If `dim = 0` the `Parameter` is viewed as constant.
- If `dim > 0` the `Parameter` is viewed as a collection of values. To generate
the parameter file we iterate through these values. `dim` essentially describes
the nesting level of the loop which does this iteration. `Parameter`s with the
same dimension are synchronized like `zip(values1, values2)`.
"""
struct Parameter{T}
    value::T
    dim::Int64
    type_tag::DataType
end
Parameter(value) = Parameter(value, 0, typeof(value))
Parameter(value, dim) = Parameter(value, dim, dim == 0 ? typeof(value) : eltype(value))



"""
    promote!(parameters::Dict)

Promotes any `Pair(key, value)` in `parameters`, where `value` is not of type
`Parameter`, to a `Pair(key, Parameter(value))`.
"""
function promote!(parameters::Dict{Symbol, Any}; aliases=Dict{Symbol, Symbol}())
    ks = keys(parameters)
    for k in ks
        if !(typeof(parameters[k]) <: Parameter)
            k in keys(aliases) && (k = aliases[k])
            parameters[k] = Parameter(parameters[k])
        end
    end
    convert(Dict{Symbol, Parameter}, parameters)
end
