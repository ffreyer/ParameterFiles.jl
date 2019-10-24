"""
    save(p::ParameterContainer)

Saves all parameter sets in the `ParameterContainer`.

Keyword Arguments:
- `path = ""`: Base path to save to
- `filenames`: Collection of file names. There should be one entry per parameter
set, i.e. `p.N` entries. Entries are synced with linear indices `1:p.N`. By
default files are named after the corresponding linear index
(`\$linear_index.param`).
"""
function save(
        p::ParameterContainer;
        path="",
        filenames = ("$(i).param" for i in 1:p.N),
        overwrite = false
    )

    if !overwrite && any(isfile(joinpath(path, fn)) for fn in filenames)
        error(
            "One or more files would be overwritten in '$path'. Set " *
            "`overwrite = true` to allow this."
        )
    end

    for (parameters, filename) in zip(p, filenames)
        open(joinpath(path, filename), "w") do f
            for (key, type_tag, value) in parameters
                write(file, key, delim, type_tag, delim, value)
                write(file, "\n")
            end
        end
    end
end


################################################################################


function load(filename::String; delim="\t")
    output = Dict{Symbol, Any}()
    open(filename, "r") do f
        for line in eachline(f)
            key, type_tag, data = split(line, delim)
            T = eval(Meta.parse(type_tag))
            if (T <: String) || (T <: Symbol)
                push!(output, Symbol(key) => T(data))
            else
                push!(output, Symbol(key) => eval(Meta.parse(data)))
            end
        end
    end
    output
end
