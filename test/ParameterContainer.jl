@testset "ParameterContainer" begin
    param = Dict(
        :A => 1,
        :B => Parameter([1, 2, 3], 1),
        :C => Parameter([10, 20], 2),
        :D => DerivedParameter(:B, :C, (b, c) -> b+c),
        :E => Parameter("ABCDEF", -1)
    )

    pc = ParameterContainer(param)

    ps = pc.param
    @test ps isa Dict{Symbol, ParameterFiles.AbstractParameter}
    @test ps[:A] == Parameter(1)
    for k in [:B, :C, :D, :E]
        @test ps[k] == param[k]
    end
    @test pc.Ndims == 2
    @test pc.N == 6
    @test pc.cdl == [1, 3]
    @test pc.dim_length == [3, 2]
    @test pc.dim_vars == [[:B], [:C]]

    for (i, result1, result2) in zip(1:6, [1, 2, 3, 1, 2, 3], [1, 1, 1, 2, 2, 2])
        @test result1 == ParameterFiles.get_value_index(pc, i, 1)
        @test result1 == ParameterFiles.get_value_index(pc, i, :B)
        @test result2 == ParameterFiles.get_value_index(pc, i, 2)
        @test result2 == ParameterFiles.get_value_index(pc, i, :C)
    end

    for k in (:A, :B, :C, :D, :E)
        @test ParameterFiles.isconstant(pc, k) == ParameterFiles.isconstant(pc.param[k])
    end

    @test isempty(pc) == false
    @test length(pc) == 6

    @test collect(pc) == Any[
        Tuple{Symbol,DataType,Bool,Any}[(:A, Int64, 1, 1), (:D, Int64, 1, 11), (:B, Int64, 1, 1), (:E, Char, 1, 'A'), (:C, Int64, 1, 10)],
        Tuple{Symbol,DataType,Bool,Any}[(:A, Int64, 1, 1), (:D, Int64, 1, 12), (:B, Int64, 1, 2), (:E, Char, 1, 'B'), (:C, Int64, 1, 10)],
        Tuple{Symbol,DataType,Bool,Any}[(:A, Int64, 1, 1), (:D, Int64, 1, 13), (:B, Int64, 1, 3), (:E, Char, 1, 'C'), (:C, Int64, 1, 10)],
        Tuple{Symbol,DataType,Bool,Any}[(:A, Int64, 1, 1), (:D, Int64, 1, 21), (:B, Int64, 1, 1), (:E, Char, 1, 'D'), (:C, Int64, 1, 20)],
        Tuple{Symbol,DataType,Bool,Any}[(:A, Int64, 1, 1), (:D, Int64, 1, 22), (:B, Int64, 1, 2), (:E, Char, 1, 'E'), (:C, Int64, 1, 20)],
        Tuple{Symbol,DataType,Bool,Any}[(:A, Int64, 1, 1), (:D, Int64, 1, 23), (:B, Int64, 1, 3), (:E, Char, 1, 'F'), (:C, Int64, 1, 20)]
    ]

    @test ParameterFiles._get_parameter_set(pc, [1, 3, 5]) == Tuple{Symbol,DataType,Bool,Any}[
        (:A, Int64, 1, 1),
        (:D, Int64, 0, [11, 13, 22]),
        (:B, Int64, 0, [1, 3, 2]),
        (:E, Char, 0, "ACE"),
        (:C, Int64, 0, [10, 10, 20])
    ]
end
