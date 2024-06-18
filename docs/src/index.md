```@meta
CurrentModule = AllocationOpt
```

# The Allocation Optimizer

This repository contains the code for the Indexer Allocation Optimizer.
The goal of this project is to enable indexers to quickly determine how to allocate so as to maximise their indexing rewards.

!!! warning
    We do *not* optimise for query fees directly, as we expect signal on a subgraph to be proportional to the query fees, as was the intention behind curation.
    Query fee information is also not public.
    It is local to each gateway.
    As a result, we will never be able to optimise with respect to query fees unless this changes.

!!! note
    By default, `opt_mode="optimal"`.
    Because of our algorithm, `optimal` mode may take a long time to converge.
    If this is the case for you, you have two options.
    You can use `opt_mode=fastgas`, which runs a different algorithm.
    This algorithm is not guaranteed to find the optimal value, and may fail to ever converge (it could hang).
    However, it still considers gas unlike the third option `opt_mode=fastnogas`.
    This is your fastest option, but it won't take into account gas costs or your preferences for max allocations.
    This mode is appropriate when you have negligible gas fees and are okay with allocating to a large number of subgraphs.

We will focus on usage of the code in this documentation.
We refer you to these [blog posts](https://semiotic.ai/articles/indexer-allocation-optimisation/) for more technical details.
If interested in how the code works, take a peek [Under The Hood](@ref)!

There are a few different ways you can run the allocation optimizer.

* [Using The Provided Binary](@ref)
* [Calling From Julia](@ref)
* [Build Your Own Binary](@ref)
* [Calling From Another Language](@ref)
