# Understanding The Output

After a successful run, the Allocation Optimizer will produce a JSON output in your `writedir` under the name *report.json*.
Let's walk through how to read this file.

This report contains the various strategies that the Allocation Optimizer recommends based on the network state and your config file.
The `num_reported_options` field in your config will determine the maximum number of outputs in the report.

Let's break down the following example *report.json*

```json
{
    "strategies": [
        {
            "num_allocations":2,
            "profit":229779.02830650925,
            "allocations": [
                {
                    "allocationAmount":"13539706.9",
                    "profit":169430.57951963632,
                    "deploymentID":"QmT2Y7SHXGRt7EKXzFPYMjnrgX64PQr86EjbsHoDLNzwLy"
                },
                {
                    "allocationAmount":"9194401.2",
                    "profit":60348.44878687295,
                    "deploymentID":"QmXT4PhR9pwAUqkxg6tgqR8xWUsTYN7V8UgmqhrrimcqXf"
                }
            ]
        },
        {
            "num_allocations":1,
            "profit":190114.2718246217,
            "allocations": [
                {
                    "allocationAmount":"22734108.1",
                    "profit":190114.2718246217,
                    "deploymentID":"QmT2Y7SHXGRt7EKXzFPYMjnrgX64PQr86EjbsHoDLNzwLy"
                }
            ]
        }
    ]
}
```

which the Optimizer generated from the following config.

```toml
id = "0xd75c4dbcb215a6cf9097cfbcc70aab2596b96a9c"
writedir = "data"
readdir = "data"
max_allocations = 2
whitelist = []
blacklist = []
frozenlist = []
pinnedlist = []
allocation_lifetime = 28
gas = 100
min_signal = 100
verbose = true
num_reported_options = 2
execution_mode = "rules"
```

!!! note
    If you use this same config, you could get a slightly different report depending on the network state.


The JSON has two `strategies`.
They are sorted by the one with the highest expected profit appearing first.
In the first one here, we have two allocations, which you could see from the `num_allocations` field, or by counting the number of entries under the `allocations` field.
At the top level of each strategy, `profit` describes the total expected profit in GRT for all allocations.

!!! warning
    Notice in the config file that our allocation lifetime was 28 epochs.
    The profit is over that lifetime.
    However, it is impossible for us to know how the network state will evolve in the future.
    All results from the Optimizer assume that the network state will remain static.
    As a result, you should take these numbers with a grain of salt and use your knowledge as an indexer
    to determine whether the Optimizer's strategy could be tweaked in your favour.
    
Then, we go into the `allocations`.
Each entry in this list contains the amount of GRT the strategy wants you to stake, the expected profit of this allocation, and the subgraph deployment ID onto which you should make this allocation.

In addition to the *report.json*, since we specified `execution_mode` as `"rules"` in the config, the Optimizer will print out indexer rules that you can run to execute the best strategy.
In our case,

```bash
graph indexer rules stop QmNoe4VQFSKAC3uiq48UQASg4QeqFVSKYYGwnxNjNi6GYX
graph indexer rules stop QmRDGLp6BHwiH9HAE2NYEE3f7LrKuRqziHBv76trT4etgU
graph indexer rules stop QmUVskWrz1ZiQZ76AtyhcfFDEH1ELnRpoyEhVL8p6NFTbR
graph indexer rules stop QmXZiV6S13ha6QXq4dmaM3TB4CHcDxBMvGexSNu9Kc28EH
graph indexer rules stop QmYN4ofRb5CUg1WdpLhhNTVCuiiAt29hBKGjTnnxYh9zYt
graph indexer rules stop Qmaz1R8vcv9v3gUfksqiS9JUz7K9G8S5By3JYn8kTiiP5K
graph indexer rules stop QmcBSr5R3K2M5tk8qeHFaX8pxAhdViYhcKD8ZegYuTcUhC
graph indexer rules set QmT2Y7SHXGRt7EKXzFPYMjnrgX64PQr86EjbsHoDLNzwLy decisionBasis always allocationAmount 13539706.9
graph indexer rules set QmXT4PhR9pwAUqkxg6tgqR8xWUsTYN7V8UgmqhrrimcqXf decisionBasis always allocationAmount 9194401.2
```

If instead you use `"actionqueue"` as the `execution_mode`, the Optimizer will populate your instance of the action queue.
