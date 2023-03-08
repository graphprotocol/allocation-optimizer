# Copyright 2022-, The Graph Foundation
# SPDX-License-Identifier: MIT

using AllocationOpt
using Test

for f in readlines(joinpath(@__DIR__, "testgroups"))
    include(f * ".jl")
end
