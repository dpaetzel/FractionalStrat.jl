using FractionalStrat
using Random
using StatsBase
using Test

for rng in Random.Xoshiro.(1:10)
    for y in [rand(rng, 10000), randn(rng, 10000)]
        idxs = fractionalstrat(rng, y, [0.8, 0.2], 100)
        @test length(idxs[1]) == 8000
        @test length(idxs[2]) == 2000

        y1 = y[idxs[1]]
        y2 = y[idxs[2]]

        @test isapprox(mean(y), mean(y1); atol=1 / 100)
        @test isapprox(mean(y), mean(y2); atol=1 / 100)
        @test isapprox(var(y), var(y1); atol=1 / 80)
        @test isapprox(var(y), var(y2); atol=1 / 80)
        for q in 0.1:0.1:0.9
            @test isapprox(quantile(y, q), quantile(y1, q); atol=1 / 100)
            @test isapprox(quantile(y, q), quantile(y2, q); atol=1 / 100)
        end
    end
end

# TODO Investigate when this strategy fails and add tests right at the edge
