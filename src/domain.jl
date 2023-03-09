# Copyright 2022-, The Graph Foundation
# SPDX-License-Identifier: MIT

const ethtogrt = 1e18

"""
    togrt(x::AbstractString)

Convert `x` to GRT.

!!! note
    This function is meant to be used with freshly queried data, so it operates on strings.
"""
togrt(x::AbstractString) = parse(Float64, x) / ethtogrt
