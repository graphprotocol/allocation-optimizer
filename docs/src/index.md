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
    By default, `opt_mode="fast"`.
    Fast-mode is not guaranteed to converge to a global optimum.
    If you get strange results, you should try `opt_mode="optimal"`.
    This mode is still experimental, and will take longer to run, but you may get more reasonable results with it.
    
We will focus on usage of the code in this documentation.
We refer you to these [blog posts](https://semiotic.ai/articles/indexer-allocation-optimisation/) for more technical details.
We also plan to post a yellowpaper at some point diving into our approach in even more detail.
Stay tuned for that!
If interested in how the code works, take a peek [Under The Hood](@ref)!

There are a few different ways you can run the allocation optimizer.

* [Using The Provided Binary](@ref)
* [Calling From Julia](@ref)
* [Build Your Own Binary](@ref)
* [Calling From Another Language](@ref)
