"""
    save(p::ParameterContainer)

Saves all parameter sets in the `ParameterContainer`.

Keyword Arguments:
- `path = ""`: Base path to save to
- `folders`: Collection of folder names. There should be one entry per parameter
set, i.e. `p.N` entries. The entries are synced with linear indices `1:p.N`. By
default, calls `(generate_name(p, i) for i in 1:N)`.
- `filenames`: Collection of file names. There should be one entry per parameter
set, i.e. `p.N` entries. Entries are synced with linear indices `1:p.N`. By
default files are named after the corresponding linear index
(`\$linear_index.param`).
"""
function save(
        p::ParameterContainer;
        path="",
        folders = (generate_name(p, i) for i in 1:N),
        filename = ("$(i).param" for i in 1:p.N)
    )

    for (i, folder, filename) in zip(1:p.N, folders, filenames)
        open(joinpath(path, folder, filename), "w") do f
            write_parameters!(f, p, i)
        end
    end
end



"""
    write_parameters(file::IOStream, p::ParameterContainer, linear_index)

Writes parameters corresponding to some `linear_index` to a `file`.
"""
function write_parameters(file::IOStream, p::ParameterContainer, idx)
    for (k, v) in p.param
        write(file, "$k\t$(v[k].type_tag)")
        if v.dim == 0
            write(file, string(v.value))
        else
            j = get_value_index(p, idx, v.dim)
            write(file, string(v.value[j]))
        end
        write(file, "\n")
    end
end
