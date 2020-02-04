module ParameterFiles

using Printf, DataStructures

include("Parameters.jl")
export Parameter, DerivedParameter
include("ParameterContainer.jl")
export ParameterContainer
include("FileIO.jl")
export save, load

include("utils.jl")
export exp_range, focused_exp_range, distribute, distribute_for_pmap
include("templating.jl")
export generate_file, resolve

include("../templates/templates.jl")

end # module
