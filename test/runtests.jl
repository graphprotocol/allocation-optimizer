using AllocationOpt
using Test

@testset "AllocationOpt.jl" begin
    include("graphrepository-test.jl")
    include("data-test.jl")
    include("gascost-test.jl")
    include("optimize-test.jl")
    include("test-e2e.jl")
end
