# There isn't really much to test for Parameters
@testset "Parameter" begin
    @test Parameter <: ParameterFiles.AbstractParameter
    @test DerivedParameter <: ParameterFiles.AbstractParameter

    # constants
    for T in (Int64, Float64, ComplexF64, Complex{Int64})
        v = rand(T)
        p = Parameter(v)
        @test p.value == v
        @test p.dim == 0
        @test p.type_tag == T
        @test ParameterFiles.isconstant(p) == true
        for dim in (-1, 0, 1)
            p = Parameter(v, dim)
            @test p.value == v
            @test p.dim == dim
            @test p.type_tag == T
            @test ParameterFiles.isconstant(p) == true
        end
    end

    # collections
    for T in (Int64, Float64, ComplexF64, Complex{Int64})
        v = rand(T, 5)
        p = Parameter(v)
        @test p.value == v
        @test p.dim == 0
        @test p.type_tag == Vector{T}
        @test ParameterFiles.isconstant(p) == true
        for dim in (-1, 0, 1)
            p = Parameter(v, dim)
            @test p.value == v
            @test p.dim == dim
            @test p.type_tag == (dim == 0 ? Vector{T} : T)
            @test ParameterFiles.isconstant(p) == (dim == 0)
        end
    end

    dp = DerivedParameter(() -> x+z+y)
    @test dp.keys == ()
    dp = DerivedParameter(:x, :y, :z, (x, y, z) -> x+z+y)
    @test dp.keys == (:x, :y, :z)
    @test ParameterFiles.isconstant(dp) == false

    param = Dict(
        :A => 1,
        :B => Parameter([1, 2, 3], 1),
        :C => Parameter([10, 20], 2),
        :D => DerivedParameter(:B, :C, (b, c) -> b+c)
    )
    ps = ParameterFiles.promote!(param)
    @test ps isa Dict{Symbol, ParameterFiles.AbstractParameter}
    @test ps[:A].value == 1
    @test ps[:A].type_tag == Int64
    @test ps[:A].dim == 0
    @test ps[:D] isa DerivedParameter
end
