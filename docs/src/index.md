```@meta
CurrentModule = AllocationOpt
```

# AllocationOpt

This repository contains the code for the indexer allocation optimiser.
The goal of this project is to enable indexers to quickly determine how to allocate so as to maximise their indexing rewards.

!!! warning
    We do *not* optimise for query fees directly, as we expect signal on a subgraph to be proportional to the query fees, as was the intention behind curation.
    Query fee information is also not public.
    It is local to each gateway.
    As a result, we will never be able to optimise with respect to query fees until this changes.
    
We will focus on usage of the code in this documentation.
We refer you to these [blog posts](https://semiotic.ai/articles/indexer-allocation-optimisation/) for more technical details.
We also plan to post a yellowpaper at some point diving into our approach in even more detail.
Stay tuned for that.



