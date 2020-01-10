
@testset "FileIO" begin
    param = Dict(
        :A => 1,
        :B => Parameter([1, 2, 3], 1),
        :C => Parameter([10, 20], 2),
        :D => DerivedParameter(:B, :C, (b, c) -> b+c),
        :E => Parameter("ABCDEF", -1)
    )
    pc = ParameterContainer(param)

    save(pc, path="temp", overwrite=true)
    @test_throws ErrorException save(pc, path="temp")
    loaded = [load("$i.param", path="temp") for i in 1:6]
    for (p, l) in zip(pc, loaded)
        sorted_p = sort(p, by=first)
        sorted_l = sort([(k, v) for (k, v) in l], by=first)
        @test first.(sorted_p) == first.(sorted_l)
        for ((pk, T, pv), (lk, lv)) in zip(sorted_p, sorted_l)
            @test pk == lk
            @test lv isa T
            @test pv == lv
        end
    end
    rm("temp", recursive=true)
end
