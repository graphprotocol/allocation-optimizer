# Copyright 2022-, The Graph Foundation
# SPDX-License-Identifier: MIT

using CSV
using TheGraphData
using Mocking
using AllocationOpt
using Test

Mocking.activate()

include("patch.jl")
for f in readlines(joinpath(@__DIR__, "testgroups"))
    include(f * ".jl")
end
