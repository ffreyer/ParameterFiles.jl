
@testset "FileIO" begin
    param = Dict(
        :A => 1,
        :B => Parameter([1, 2, 3], 1),
        :C => Parameter([10, 20], 2),
        :D => DerivedParameter(:B, :C, (b, c) -> b+c),
        :E => Parameter("ABCDEF", -1),
        :F => Parameter("const", 0)
    )
    pc = ParameterContainer(param)

    save(pc, path="temp", overwrite=true)

    @test_throws ErrorException save(pc, path="temp")

    loaded = [load("$i.param", path="temp") for i in 1:6]
    for (p, l) in zip(pc, loaded)
        sorted_p = sort(p, by=first)
        sorted_l = sort([(k, v) for (k, v) in l], by=first)
        @test first.(sorted_p) == first.(sorted_l)
        for ((pk, T, isconst, pv), (lk, lv)) in zip(sorted_p, sorted_l)
            @test pk == lk
            @test lv isa T
            @test pv == lv
        end
    end

    # Test chunked saves
    save(pc, [[[1], [3], [5]], [[2, 4, 6]]], path="temp", overwrite=true)
    loaded = [load("$i.param", path="temp") for i in 1:6]
    expected = collect(pc)
    check(p, l) = begin
        sorted_p = sort(p, by=first)
        sorted_l = sort([(k, v) for (k, v) in l], by=first)
        @test first.(sorted_p) == first.(sorted_l)
        for ((pk, T, isconst, pv), (lk, lv)) in zip(sorted_p, sorted_l)
            @test pk == lk
            @test lv isa T
            @test pv == lv
        end
    end

    check(expected[1], loaded[1][1][1])
    check(expected[3], loaded[1][2][1])
    check(expected[5], loaded[1][3][1])
    check(expected[2], loaded[2][1][1])
    check(expected[4], loaded[2][1][2])
    check(expected[6], loaded[2][1][3])

    rm("temp", recursive=true)
end
