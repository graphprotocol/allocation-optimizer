# Build Your Own Binary

Compiling the binary yourself is an excellent way to use the Allocation Optimizer.
You should use this route if a couple of reasons speak to you.

1. You'd prefer not to trust a random binary off the internet.
2. You have added your own features to the Allocation Optimizer, but would prefer the large, one-time cost of AOT compilation as opposed the small, every-time cost of JIT compilation.

In this documentation, we'll take you through the process of generating an app binary.

!!! note
    You can instead compile to a sysimage or to a library, but we don't natively support those ourselves.
    Look through the [PackageCompiler](https://julialang.github.io/PackageCompiler.jl/stable/index.html) documentation for steps if you would prefer one of those options..
    
    
Install Julia!
We prefer to use `juliaup`.
You can install this via:
   
```bash
curl -fsSL https://install.julialang.org | sh
```
   
!!! note
    As of writing this documentation, the latest version of Julia is v1.8.
    This the version the Allocation Optimizer currently uses, and the version `juliaup` will install by default.
    If `juliaup` begins to use v1.9, then you may need to use `juliaup` to manually install v1.8 via `juliaup add 1.8`. Then, you can either set the default to be v1.8 using `juliaup default 1.8`, or you can replace every time you see `julia` with `julia +1.8` below.

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

Install a C-compiler such as [GCC](https://gcc.gnu.org/) or [Clang](https://clang.llvm.org/).

From the Julia REPL (the TUI that comes up when you use `julia --project`), compile your app.

```julia
julia> using PackageCompiler
julia> create_app(".", "app")
```
!!! note
    If you are still in Pkg mode, `pkg>`, hitting *backspace* will bring you back into the REPL.

Set up your configuration file.
See [Configuration](@ref) for details.

Run the binary pointing at the configuration TOML that you would like to use.

``` sh
./app/bin/AllocationOpt /path/to/your_config.toml
```
