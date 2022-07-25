@testset "service" begin
    @testset "detach_indexer" begin
        repo = Repository(
            [
                Indexer("0x00", 10.0, [Allocation("Qmaaa", 10.0, 0)]),
                Indexer("0x01", 20.0, [Allocation("Qmaaa", 10.0, 0)]),
            ],
            [SubgraphDeployment("1x00", "Qmaaa", 10.0)],
        )

        # Should detach the specified indexer
        id = "0x00"
        indexer, frepo = detach_indexer(repo, id)
        @test frepo.indexers[1].id == "0x01"
        @test length(frepo.indexers) == 1
        @test indexer.id == "0x00"

        # Should throw an exception when `id` not in repo
        id = "0x10"
        @test_throws UnknownIndexerError detach_indexer(repo, id)
    end

    @testset "signal" begin
        subgraphs = [SubgraphDeployment("1x00", "Qmaaa", 10.0)]

        # Should get the signal of the one defined subgraph
        @test signal.(subgraphs) == [10.0]
    end

    @testset "ipfshash" begin
        subgraphs = [SubgraphDeployment("1x00", "Qmaaa", 10.0)]

        # Should get the ipfshash of the one defined subgraph
        @test ipfshash.(subgraphs) == ["Qmaaa"]
    end

    @testset "allocation" begin
        indexers = [
            Indexer("0x00", 10.0, [Allocation("Qmaaa", 10.0, 0)]),
            Indexer("0x01", 20.0, [Allocation("Qmaaa", 20.0, 0)]),
        ]

        # Should get the allocations of indexers
        @test allocation.(indexers) ==
            [[Allocation("Qmaaa", 10.0, 0)], [Allocation("Qmaaa", 20.0, 0)]]
    end

    @testset "allocated_stake" begin
        allocs = [Allocation("Qmaaa", 10.0, 0), Allocation("Qmaaa", 20.0, 0)]

        # Should get the allocations of indexers
        @test allocated_stake.(allocs) == [10.0, 20.0]
    end

    @testset "stakes" begin
        repo = Repository(
            [
                Indexer(
                    "0x00",
                    10.0,
                    [Allocation("Qmaaa", 10.0, 0), Allocation("Qmbbb", 10.0, 0)],
                ),
                Indexer("0x01", 20.0, [Allocation("Qmaaa", 10.0, 0)]),
            ],
            [SubgraphDeployment("1x00", "Qmaaa", 10.0)],
        )
        # Should get the sum of stake of the one defined subgraph
        @test stakes(repo) == [20.0]

        repo = Repository(
            [
                Indexer("0x00", 10.0, [Allocation("Qmaaa", 10.0, 0)]),
                Indexer("0x01", 20.0, [Allocation("Qmccc", 8.0, 0)]),
            ],
            [
                SubgraphDeployment("1x00", "Qmaaa", 10.0),
                SubgraphDeployment("1x01", "Qmbbb", 5.0),
                SubgraphDeployment("1x01", "Qmccc", 5.0),
            ],
        )

        # Should get proper sum of stake according to the subgraph ids
        @test stakes(repo) == [10.0, 0.0, 8.0]
    end

    @testset "optimize" begin
        repo = Repository(
            [
                Indexer(
                    "0x01", 10.0, [Allocation("Qmaaa", 1.0, 0), Allocation("Qmbbb", 7.0, 0)]
                ),
            ],
            [
                SubgraphDeployment("1x00", "Qmaaa", 10.0),
                SubgraphDeployment("1x01", "Qmbbb", 5.0),
            ],
        )
        indexer = Indexer("0x00", 5.0, Allocation[])
        Ω = stakes(repo)
        ψ = signal.(repo.subgraphs)
        σ = stake(indexer)
        ω = optimize(Ω, ψ, σ)
        @test isapprox(ω, [4.2, 0.8], atol=0.1)
    end

    @testset "projectsimplex" begin
        # Shouldn't project since already on simplex
        x = [5, 2, 8]
        z = 15
        @test projectsimplex(x, z) == x

        # Should set negative value to zero and scale others up
        # to be on simplex
        x = [-5, 2, 8]
        z = 15
        w = projectsimplex(x, z)
        @test sum(w) == z
        @test all(w .≥ 0)
        @test w[1] < w[2] < w[3]

        # Should scale values down to be on simplex
        x = [20, 2, 8]
        z = 15
        w = projectsimplex(x, z)
        @test sum(w) == z
        @test all(w .≥ 0)
        @test w[2] < w[3] < w[1]
    end

    @testset "∇f" begin
        # ω is 0
        ψ = Float64[5, 2, 8]
        Ω = Float64[2, 1, 1]
        ω = Float64[0, 0, 0]
        df = ∇f.(ω, ψ, Ω)
        @test df ≈ [-2.5, -2, -8]
    end

    @testset "discount" begin
        # τ = 1.0
        Ω = Float64[2, 5, 3]
        ψ = Float64[7, 2, 1]
        σ = 10.0
        τ = 1.0
        Ωnew = discount(Ω, ψ, σ, τ)
        Ω0 = zeros(length(Ω))
        @test Ωnew == optimize(Ω0, ψ, σ)

        # τ = 0.0
        τ = 0.0
        Ωnew = discount(Ω, ψ, σ, τ)
        @test Ωnew == Ω

        # τ = 0.2, result should still sum to σ because of simplex projection
        τ = 0.2
        Ωnew = discount(Ω, ψ, σ, τ)
        @test sum(Ωnew) == σ
    end

    @testset "gssp" begin
        # Shouldn't project since already on simplex
        x = [5, 2, 8, 0, 1]
        k = 3
        σ = 15
        @test gssp(x, k, σ) == [5, 2, 8, 0, 0]

        # Should set negative value to zero and scale others up
        # to be on simplex
        x = [-5, 2, 8, -10, -8]
        k = 3
        σ = 15
        @test gssp(x, k, σ) == [0, 4.5, 10.5, 0, 0]

        # Should scale values down to be on simplex
        x = [20, 2, 8, 1, 7]
        k = 3
        σ = 15
        w = gssp(x, k, σ)
        @test sum(w) ≈ σ
        @test all(w .≥ 0)
        @test w[1] > w[3] > w[5]
    end

    @testset "pgd_step" begin
        # ω is 0
        ψ = Float64[5, 2, 8]
        Ω = Float64[2, 1, 1]
        ω = Float64[0, 0, 0]
        k = 2
        σ = 15
        η = 1
        ω₁ = pgd_step(ω, ψ, Ω, k, σ, η)
        @test ω₁ ≈ [4.75, 0.0, 10.25]

        # η is 0
        ψ = Float64[5, 2, 8]
        Ω = Float64[2, 1, 1]
        ω = Float64[0, 0, 0]
        k = 2
        σ = 15
        η = 0
        ω₁ = pgd_step(ω, ψ, Ω, k, σ, η)
        @test ω₁ ≈ [7.5, 7.5, 0.0]
    end

    @testset "pgd" begin
        ψ = Float64[5, 2, 8]
        Ω = Float64[2, 1, 1]
        k = 1
        σ = 15
        η = 10000
        Δη = 1.001
        patience = 1e4
        tol = 1e-3
        ω₁ = pgd(ψ, Ω, k, σ, η, Δη, patience, tol)
        @test ω₁ == [0.0, 0.0, 15.0]
    end

    @testset "optimize pgd" begin
        # k = 2
        filter_fn = (a, b, c) -> a[:, end]
        a = 1e5
        b = 1e7
        ψ = Float64[5, 8] * a
        Ω = Float64[2, 1] * b
        σ = 15.0 * b
        ωopt = optimize(Ω, ψ, σ)
        ψ = Float64[5, 2, 8] * a
        Ω = Float64[2, 1, 1] * b
        k = 2
        ω = optimize(Ω, ψ, σ, k, filter_fn)
        @test isapprox(ωopt, ω[findall(ω .!= 0.0)]; rtol=1e-2)
    end

    @testset "tokens_issued_over_lifetime" begin
        principle = 100.0
        issurance_per_block = 1.0001
        block_per_epoch = 30
        total_token_signalled = 15.0
        current_epoch = 0
        network = GraphNetworkParameters("1", principle, issurance_per_block, block_per_epoch, total_token_signalled, current_epoch)
        # Tokens issued over 1 epoch
        allocation_lifetime = 1
        n = tokens_issued_over_lifetime(network, allocation_lifetime)
        @test isapprox(n, 0.300435; rtol=1e-2)
        
        # Tokens issued over 10 epoch
        allocation_lifetime = 10
        n = tokens_issued_over_lifetime(network, allocation_lifetime)
        @test isapprox(n, 3.0453; rtol=1e-2)
    end

    @testset "f" begin
        # f(ψ::Vector{T}, Ω::Vector{T}, ω::Vector{T}, Φ::T, Ψ::T)
        ψ = Float64[2, 4, 1]
        Ω = Float64[0, 10, 4]
        ω = Float64[1, 1, 1]
        Φ = 3.0
        Ψ = 7.0
        rewards = f(ψ, Ω, ω, Φ, Ψ)
        @test isapprox(rewards, 1.0987; rtol=1e-2)
    end

    @testset "profits" begin
        principle = 100.0
        issurance_per_block = 1.001
        block_per_epoch = 30
        total_token_signalled = 15.0
        current_epoch = 0
        gas = 0.01
        # Tokens issued over 1 epoch
        network = GraphNetworkParameters("1", principle, issurance_per_block, block_per_epoch, total_token_signalled, current_epoch)
        allocation_lifetime = 1
        
        ψ = Float64[2, 4, 1]
        Ω = Float64[0, 10, 4]
        ω = Float64[1, 1, 1]
        Φ = tokens_issued_over_lifetime(network, allocation_lifetime)
        prof = profit(network, gas, allocation_lifetime, ω, ψ, Ω)
        x = f(ψ, Ω, ω, Φ, total_token_signalled)-gaspersubgraph(gas)*length(ω[findall(ω .!= 0.0)])
        @test isapprox(prof, x; rtol=1e-2)
    end
end
