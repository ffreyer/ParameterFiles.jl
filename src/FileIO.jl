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
    for (i, filename) in zip(1:p.N, filenames)
        open(joinpath(path, filename), "w") do f
            write_parameters!(f, p, i)
        end
    end
end



"""
    write_parameters!(file::IOStream, p::ParameterContainer, linear_index)

Writes parameters corresponding to some `linear_index` to a `file`.
"""
function write_parameters!(
        file::IOStream, p::ParameterContainer, idx;
        delim="\t"
    )

    for (k, v) in p.param
        write(file, "$k", delim, "$(v.type_tag)", delim)
        if v.dim == 0
            write(file, string(v.value))
        else
            j = get_value_index(p, idx, v.dim)
            write(file, string(v.value[j]))
        end
        write(file, "\n")
    end

    nothing
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
