using AllocationOpt
using Test

@testset "AllocationOpt.jl" begin
    include("graphrepository-test.jl")
    include("data-test.jl")
    include("optimize-test.jl")
end
