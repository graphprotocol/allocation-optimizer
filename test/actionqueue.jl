@testset "ActionQueue" begin
    @testset "structtodict" begin
        # Should convert the struct fields to dict keys and the field values to dict values
        struct Foo <: ActionQueue.ActionInput
            a::Integer
            b::Integer
        end
        foo = Foo(1, 2)
        @test ActionQueue.structtodict(foo) == Dict("a" => 1, "b" => 2)
    end

    @testset "reallocate_actions" begin
        # Should reallocate two existing allocations
        proposed_allocations = Dict("Qmaaa" => 1.0, "Qmbbb" => 2.0, "Qmccc" => 3.0)
        proposed_ipfs = collect(keys(proposed_allocations))
        existing_allocations = Dict(
            "Qmccc" => "0x000", "Qmaaa" => "0x001", "Qmddd" => "0x010"
        )
        existing_ipfs = collect(keys(existing_allocations))
        actions, _ = ActionQueue.reallocate_actions(
            proposed_ipfs, existing_ipfs, proposed_allocations, existing_allocations
        )
        @test length(actions) == 2

        # Created actions should be of type ActionQueue.reallocate
        proposed_allocations = Dict("Qmaaa" => 1.0, "Qmbbb" => 2.0, "Qmccc" => 3.0)
        proposed_ipfs = collect(keys(proposed_allocations))
        existing_allocations = Dict(
            "Qmccc" => "0x000", "Qmeee" => "0x001", "Qmddd" => "0x010"
        )
        existing_ipfs = collect(keys(existing_allocations))
        actions, _ = ActionQueue.reallocate_actions(
            proposed_ipfs, existing_ipfs, proposed_allocations, existing_allocations
        )
        @test length(actions) == 1
        @test actions[1]["type"] == ActionQueue.reallocate
    end

    @testset "allocate_actions" begin
        # Should open one allocation
        proposed_allocations = Dict("Qmaaa" => 1.0, "Qmbbb" => 2.0, "Qmccc" => 3.0)
        proposed_ipfs = collect(keys(proposed_allocations))
        reallocate_ipfs = ["Qmbbb", "Qmccc"]
        actions, _ = ActionQueue.allocate_actions(
            proposed_ipfs, reallocate_ipfs, proposed_allocations
        )
        @test length(actions) == 1
        @test actions[1]["type"] == ActionQueue.allocate
    end

    @testset "unallocate_actions" begin
        # Should close zero allocation
        existing_allocations = Dict(
            "Qmbbb" => "0x000", "Qmaaa" => "0x001", "Qmccc" => "0x010"
        )
        existing_ipfs = collect(keys(existing_allocations))
        reallocate_ipfs = ["Qmbbb", "Qmccc"]
        frozenlist = ["Qmaaa"]
        actions, _ = ActionQueue.unallocate_actions(
            existing_allocations, existing_ipfs, reallocate_ipfs, frozenlist
        )
        @test length(actions) == 0

        # Should close one allocation
        existing_allocations = Dict(
            "Qmbbb" => "0x000", "Qmaaa" => "0x001", "Qmccc" => "0x010"
        )
        existing_ipfs = collect(keys(existing_allocations))
        reallocate_ipfs = ["Qmbbb", "Qmccc"]
        frozenlist = String[]
        actions, _ = ActionQueue.unallocate_actions(
            existing_allocations, existing_ipfs, reallocate_ipfs, frozenlist
        )
        @test length(actions) == 1
        @test actions[1]["type"] == ActionQueue.unallocate
    end
end
