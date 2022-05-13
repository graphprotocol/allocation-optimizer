@testset "domain" begin
    include("../src/domain.jl")

    @testset "verify_ipfshash" begin
        # Should fail because not long enough
        hash = "Qmaaa"
        @test !verify_ipfshash(hash)

        # Should fail because doesn't start with "Qm"
        hash = "AmauYgPmss6CEZXtaRvvGW2oiyLqxpoCkWNCTmFPVTFDfk"
        @test !verify_ipfshash(hash)

        # Should pass
        hash = "QmauYgPmss6CEZXtaRvvGW2oiyLqxpoCkWNCTmFPVTFDfk"
        @test verify_ipfshash(hash)
    end
end
