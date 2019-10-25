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


function save(
        p::ParameterContainer,
        chunks::Vector{Vector{Int}};
        path="",
        filenames = ("$(i).param" for i in 1:length(chunks)),
        overwrite = false
    )

    if !overwrite && any(isfile(joinpath(path, fn)) for fn in filenames)
        error(
            "One or more files would be overwritten in '$path'. Set " *
            "`overwrite = true` to allow this."
        )
    end

    for (chunk, filename) in zip(chunks, filenames)
        open(joinpath(path, filename), "w") do f
            write(f, "chunks\t$(length(chunk))\n")
            for (key, param) in p.params
                values = if param.dim == 0
                    [param.value for _ in chunk]
                else
                    map(chunk) do i
                        param.value[get_value_index(p, i, param.dim)]
                    end
                end
                write(file, key, delim, param.type_tag, delim, values)
                write(file, "\n")
            end
        end
    end
end




################################################################################


function load(filename::String; delim="\t")
    output = Dict{Symbol, Any}()
    ischunked = false
    open(filename, "r") do f
        for line in eachline(f)
            if startswith(line, "chunks")
                @assert isempty(output) "\"chunks\" should appear first in the file."
                chunk_size = parse(Int64, split(line, "\t")[2])
                output = [Dict{Symbol, Any}() for _ in 1:chunk_size]
                ischunked = true
                continue
            end

            key, type_tag, data = split(line, delim)

            if !ischunked
                T = eval(Meta.parse(type_tag))
                if ((T <: String) || (T <: Symbol))
                    push!(output, Symbol(key) => T(data))
                else
                    push!(output, Symbol(key) => eval(Meta.parse(data)))
                end
            else
                xs = eval(Meta.parse(data))
                @assert length(xs) == length(output)
                for (i, x) in enumerate(xs)
                    push!(output[i], Symbol(key) => x)
                end
            end
        end
    end
    output
end
