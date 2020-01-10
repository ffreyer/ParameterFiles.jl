using ParameterFiles, Test

@testset "ParameterFiles" begin
    include("Parameter.jl")
    include("ParameterContainer.jl")
    include("FileIO.jl")
end
