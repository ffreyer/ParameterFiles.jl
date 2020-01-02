"""
    save(p::ParameterContainer[, chunks])

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
        delim = "\t",
        overwrite = false
    )
    isdir(path) || mkdir(path)
    if !overwrite && any(isfile(joinpath(path, fn)) for fn in filenames)
        error(
            "One or more files would be overwritten in '$path'. Set " *
            "`overwrite = true` to allow this."
        )
    end

    for (parameters, filename) in zip(p, filenames)
        open(joinpath(path, filename), "w") do file
            for (key, type_tag, value) in parameters
                println(file, key, delim, type_tag, delim, value)
            end
        end
    end
end


function save(
        p::ParameterContainer,
        chunks::Vector{Vector{Vector{Int}}};
        path="",
        filenames = ("$(i).param" for i in 1:length(chunks)),
        delim = "\t",
        overwrite = false,
    )
    isdir(path) || mkdir(path)
    if !overwrite && any(isfile(joinpath(path, fn)) for fn in filenames)
        error(
            "One or more files would be overwritten in '$path'. Set " *
            "`overwrite = true` to allow this."
        )
    end

    for (sub_chunks, filename) in zip(chunks, filenames)
        open(joinpath(path, filename), "w") do file
            print(file, "chunks\t")
            join(file, string.(length.(sub_chunks)), "\t")
            println(file)
            for (key, type_tag, values) in _get_parameter_set(p, vcat(sub_chunks...))
                println(file, key, delim, type_tag, delim, values)
            end
        end
    end
end




################################################################################

"""
    load(filename[: path ="", delim="\t"])

Loads parameters from a previously saved parameter file. Returns a dictionary
`key::Symbol => value` which can be passed to a function as keyword arguments
via `foo(; dict...)`.
If the ParameterContainer was saved with chunks, this will return an array of
dictionaries instead.
"""
function load(filename::String; path="", delim="\t")
    output = Dict{Symbol, Any}()
    ischunked = false
    chunk_sizes = Int64[]
    open(joinpath(path, filename), "r") do f
        for line in eachline(f)
            if startswith(line, "chunks")
                @assert isempty(output) "\"chunks\" should appear first in the file."
                chunk_sizes = parse.(Int64, split(line, "\t")[2:end])
                output = [[Dict{Symbol, Any}() for _ in 1:L] for L in chunk_sizes]
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
                @assert length(xs) == sum(chunk_sizes)
                j = 1
                block_start = 0
                for (i, x) in enumerate(xs)
                    push!(output[j][i-block_start], Symbol(key) => x)
                    if chunk_sizes[j] <= i - block_start
                        block_start += chunk_sizes[j]
                        j += 1
                    end
                end
            end
        end
    end
    output
end
