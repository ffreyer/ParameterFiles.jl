module ParameterFiles

using Printf, DataStructures

include("Parameters.jl")
export Parameter, DerivedParameter
include("ParameterContainer.jl")
export ParameterContainer
include("FileIO.jl")
export save, load

include("utils.jl")
export exp_range, focused_exp_range, bundle_parameters
include("templating.jl")
export generate_file

include("../templates/templates.jl")

end # module
