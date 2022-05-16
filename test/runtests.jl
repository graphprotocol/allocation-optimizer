using AllocationOpt
using Test

@testset "AllocationOpt.jl" begin
    include("../src/exceptions.jl")
    include("../src/domainmodel.jl")
    include("../src/query.jl")
    include("../src/service.jl")

    # Tests
    include("domainmodel.jl")
    include("query.jl")
    include("service.jl")

    @testset "optimize_indexer" begin
        @test_throws AllocationOpt.UnknownIndexerError optimize_indexer(
            "0x6ac85b9d834b51b14a7b0ed849bb5199e", String[], String[], String[], String[]
        )
        @test_throws AllocationOpt.BadSubgraphIpfsHashError optimize_indexer(
            "0x6ac85b9d834b51b14a7b0ed849bb5199e04c05c5",
            String[""],
            String["QmP4oSiQ7Wc4JTFk86m2JxGvR912NyBbxJnEdZawkYLTk4"],
            String[],
            String[],
        )
    end
end
