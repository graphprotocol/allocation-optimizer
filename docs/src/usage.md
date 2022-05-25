# Usage

## Configuring The Indexer Service

Set indexer-service flag `--serve-network-subgraph` to `true` so optimiser can pull data from the network subgraph at the indexer-service's network endpoint.
If you would like to keep it false, you can instead supply an API url to `indexer_service_network_url`.

## CLI Usage

1. Download the [*allocationopt* script](https://raw.githubusercontent.com/graphprotocol/AllocationOpt.jl/main/scripts/allocationopt). For example, using `curl` or `wget`. Make sure you use the raw file!
2. Make the *allocationopt* script executable.

```bash
$ chmod +x allocationopt
```

3. Run the *allocationopt* script. If this doesn't work, check that the shebang in the allocationopt file points to your julia executable.

```bash
$ ./scripts/allocationopt --help
$ ./scripts/allocationopt "0x6ac85b9d834b51b14a7b0ed849bb5199e04c05c5" test/example.csv 0.0 10 http://localhost:18000 http://localhost:7600/network
```

3. On Linux, you can further simplify the use of this script by symlinking it to your *.local/bin*

```
$ mkdir -p ~/.local/bin
$ cd ~/.local/bin
$ ln -s ~/projects/AllocationOpt.jl/scripts/allocationopt .  # Change to the path to the allocationopt script for you
```

You should now be able to run the *allocationopt* script from anywhere! Similarly to how you'd run *ls*.
