# Copyright 2022-, The Graph Foundation
# SPDX-License-Identifier: MIT

"""
    groupunique(x::AbstractVector)

Find the indices of each unique value in `x`

```julia
julia> using AllocationOpt
julia> x = [1, 2, 1, 3, 2, 3]
julia> AllocationOpt.groupunique(x)
```
"""
groupunique(x::AbstractVector) = SAC.groupfind(unique, x)
