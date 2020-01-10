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
        Tuple{Symbol,DataType,Any}[(:A, Int64, 1), (:D, Int64, 11), (:B, Int64, 1), (:E, Char, 'A'), (:C, Int64, 10)],
        Tuple{Symbol,DataType,Any}[(:A, Int64, 1), (:D, Int64, 12), (:B, Int64, 2), (:E, Char, 'B'), (:C, Int64, 10)],
        Tuple{Symbol,DataType,Any}[(:A, Int64, 1), (:D, Int64, 13), (:B, Int64, 3), (:E, Char, 'C'), (:C, Int64, 10)],
        Tuple{Symbol,DataType,Any}[(:A, Int64, 1), (:D, Int64, 21), (:B, Int64, 1), (:E, Char, 'D'), (:C, Int64, 20)],
        Tuple{Symbol,DataType,Any}[(:A, Int64, 1), (:D, Int64, 22), (:B, Int64, 2), (:E, Char, 'E'), (:C, Int64, 20)],
        Tuple{Symbol,DataType,Any}[(:A, Int64, 1), (:D, Int64, 23), (:B, Int64, 3), (:E, Char, 'F'), (:C, Int64, 20)]
    ]

    @test ParameterFiles._get_parameter_set(pc, [1, 3, 5]) == Tuple{Symbol,DataType,Any}[
        (:A, Int64, 1),
        (:D, Int64, [11, 13, 22]),
        (:B, Int64, [1, 3, 2]),
        (:E, Char, "ACE"),
        (:C, Int64, [10, 10, 20])
    ]
end
