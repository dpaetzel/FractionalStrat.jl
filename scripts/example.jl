using FractionalStrat
using UnicodePlots
using Random
using StatsBase

N = 50
split = 0.8

diffs_meantrainuniform = Float64[]
diffs_meantestuniform = Float64[]
diffs_meantrainfs = Float64[]
diffs_meantestfs = Float64[]

diffs_vartrainuniform = Float64[]
diffs_vartestuniform = Float64[]
diffs_vartrainfs = Float64[]
diffs_vartestfs = Float64[]

for seed in 1:100000
    rng = Random.Xoshiro(seed)

    X = rand(rng, N)
    y = @. 3 * X + 1 + randn(rng) * 0.15

    idxs = shuffle(1:N)
    idxs_uniform =
        (idxs[1:Int(floor(N * split))], idxs[Int((floor(N * split)) + 1):end])
    idxs_fs = fractionalstrat(y, [split, 1 - split], 7)

    Xtrain_uniform, ytrain_uniform = X[idxs_uniform[1]], y[idxs_uniform[1]]
    Xtest_uniform, ytest_uniform = X[idxs_uniform[2]], y[idxs_uniform[2]]
    push!(diffs_meantrainuniform, abs(mean(y) - mean(ytrain_uniform)))
    push!(diffs_meantestuniform, abs(mean(y) - mean(ytest_uniform)))
    push!(diffs_vartrainuniform, var(y) - var(ytrain_uniform))
    push!(diffs_vartestuniform, var(y) - var(ytest_uniform))

    Xtrain_fs, ytrain_fs = X[idxs_fs[1]], y[idxs_fs[1]]
    Xtest_fs, ytest_fs = X[idxs_fs[2]], y[idxs_fs[2]]
    push!(diffs_meantrainfs, abs(mean(y) - mean(ytrain_fs)))
    push!(diffs_meantestfs, abs(mean(y) - mean(ytest_fs)))
    push!(diffs_vartrainfs, var(y) - var(ytrain_fs))
    push!(diffs_vartestfs, var(y) - var(ytest_fs))
end

display(
    histogram(
        diffs_meantrainuniform .- diffs_meantrainfs;
        nbins=50,
        vertical=true,
    ),
)
display(
    histogram(
        diffs_meantestuniform .- diffs_meantestfs;
        nbins=50,
        vertical=true,
    ),
)
display(
    histogram(
        diffs_vartrainuniform .- diffs_vartrainfs;
        nbins=50,
        vertical=true,
    ),
)
display(
    histogram(
        diffs_vartestuniform .- diffs_vartestfs;
        nbins=50,
        vertical=true,
    ),
)

println(
    "Mean and std of the difference (uniform - stratified sampling) of mean " *
    "differences to the original data mean for 80/20 splits",
)
println("80% block:")
mean_mean = mean(diffs_meantrainuniform .- diffs_meantrainfs)
std_mean = std(diffs_meantrainuniform .- diffs_meantrainfs)
mean_var = mean(diffs_vartrainuniform .- diffs_vartrainfs)
std_var = std(diffs_vartrainuniform .- diffs_vartrainfs)
@show mean_mean
@show std_mean
@show mean_var
@show std_var

println("20% block:")
mean_mean = mean(diffs_meantestuniform .- diffs_meantestfs)
std_mean = std(diffs_meantestuniform .- diffs_meantestfs)
mean_var = mean(diffs_vartestuniform .- diffs_vartestfs)
std_var = std(diffs_vartestuniform .- diffs_vartestfs)
@show mean_mean
@show std_mean
@show mean_var
@show std_var
