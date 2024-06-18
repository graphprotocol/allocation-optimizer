# Calling From Julia


If you're okay with having the Julia runtime on your computer, and you don't mind the precompilation time (around 3 seconds), this is the preferred way to run the Allocation Optimizer.
In part, this is because access the to Julia runtime will enable you to add your own features if you'd like.
You can even (hopefully) even submit some PRs with features to help other indexers!
Compiling on your machine also allows Julia to specialise on idiosyncrasies of your hardware.
For example, if your CPU supports [AVX-512](https://en.wikipedia.org/wiki/AVX-512), Julia will use those instructions to speed up your code beyond what the generic binary might give you.
Again, the trade-off here is that you'll have to eat the precompilation time the first time you run the code after you start a new Julia session.

That said, here's how to install and use the Allocation Optimizer from Julia.

Install Julia!
We prefer to use `juliaup`.
You can install this via:

```bash
curl -fsSL https://install.julialang.org | sh
```

!!! note
    As of writing this documentation, the latest version of Julia is v1.10.
    This the version the Allocation Optimizer currently uses, and the version `juliaup` will install by default.
    If `juliaup` begins to use v1.11, then you may need to use `juliaup` to manually install v1.10 via `juliaup add 1.10`. Then, you can either set the default to be v1.10 using `juliaup default 1.10`, or you can replace every time you see `julia` with `julia +1.10` below.


Clone this repository and `cd` into it.

```bash
git clone https://github.com/graphprotocol/allocation-optimizer.git
cd allocation-optimizer
```

Start Julia.

```bash
julia --project
```

Install the dependencies

```julia
julia> ]
pkg> instantiate
```

Set up your configuration file.
See [Configuration](@ref) for details.

From the Julia REPL (the TUI that comes up when you use `julia --project`), run the `main` function with the path to your config.

```julia
julia> using AllocationOpt
julia> path = "config.toml"  # path to your config file
julia> AllocationOpt.main(path)
```

!!! note
    If you are still in Pkg mode, `pkg>`, hitting *backspace* will bring you back into the REPL.
