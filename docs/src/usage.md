# Usage

## CLI script

1. Download the [*allocationopt* script](https://raw.githubusercontent.com/graphprotocol/AllocationOpt.jl/main/scripts/allocationopt). For example, using `curl` or `wget`. Make sure you use the raw file!

2. On MacOS, if you have already added Julia path to `usr/local/bin`, you would need to change shebang of downloaded script to `#!/usr/local/bin/julia` or your specific customized path.

Linux (Default)
```bash
#!/usr/bin/julia 
```
MacOS 
```bash
#!/usr/local/bin/julia
```

3. Make the *allocationopt* script executable. 
```bash
$ chmod +x allocationopt
```

4. A simple check here, make sure you have Comonicon package added to Julia environment. 
```bash
$ ./scripts/allocationopt --help
```

5. On Linux, you can further simplify the use of this script by symlinking it to your *.local/bin*

```
$ mkdir -p ~/.local/bin
$ cd ~/.local/bin
$ ln -s ~/projects/AllocationOpt.jl/scripts/allocationopt .  # Change to the path to the allocationopt script for you
```
You should now be able to run the *allocationopt* script from anywhere! Similarly to how you'd run *ls*.

6. Optimiser queries network subgraph data to optimize. We recommend making queries to network subgraph served by your own indexer service, alternatively you can supply an API url to `indexer_service_network_url` from decentralized gateway or hosted service. 

To provide network subgraph to optimiser, set indexer-service flag `--serve-network-subgraph` to `true`. We might incorporate bearer Auth token checks in the future. 

7. Populate your preferred lists (whitelist, blacklist, pinnedlist, frozenlist) into a CSV and remember its file path


## ActionQueue

This command requires a URL to indexer management server and a URL to make graph network subgraph queries.

Run the *allocationopt* script with the *actionqueue* option. Check help for detail inputs.

```bash
$ ./scripts/allocationopt actionqueue "0x6ac85b9d834b51b14a7b0ed849bb5199e04c05c5" 1 test/example.csv 50 1 5 0.0 http://localhost:18000 http://localhost:7600/network
```
If this doesn't work, check that the shebang in the allocationopt file points to your julia executable. 

Upon success, you should see a 'Done!' printed; on the indexer service side, requests from our tool is logged, and you can use indexer CLI `actions` commands to check and approve actions. 

## Indexer Rules

If you don't have the action queue set up yet, you can also run the optimiser by telling it to generate indexing rules. 

Indexer still need to pay attention to how the agent reacts to these rules, and reallocation is broken into 2 separate rules: indexer must send `close` transaction before sending `allocate`.

Run the *allocationopt* script with the *rules* option. The URL passed in should be an API URL

```bash
$ ./scripts/allocationopt --help
$ ./scripts/allocationopt rules "0x6ac85b9d834b51b14a7b0ed849bb5199e04c05c5" 1 test/example.csv 50 1 5 0.0 http://localhost:7600/network
```

If this doesn't work, check that the shebang in the allocationopt file points to your julia executable.
