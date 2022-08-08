var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = AllocationOpt","category":"page"},{"location":"#AllocationOpt","page":"Home","title":"AllocationOpt","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for AllocationOpt.","category":"page"},{"location":"","page":"Home","title":"Home","text":"AllocationOpt is a library for optimising how an indexer should allocate its stake in The Graph Protocol.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Important: You must run this on a computer that supports 64-bit operations. 32-bit doesn't have enough precision to solve the optimisation problem.","category":"page"},{"location":"#Installation","page":"Home","title":"Installation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Enter the julia repl. On linux machines, this is as simple as running the julia command from your terminal emulator. For MacOS, you'll need to add Julia to your path. See this StackOverflow post if you're having issues.\nAdd this package by adding the github url. First, enter package mode ]. Then, type add https://github.com/graphprotocol/AllocationOpt.jl. You'll also want to add the Comonicon package.","category":"page"},{"location":"","page":"Home","title":"Home","text":"pkg> add https://github.com/graphprotocol/AllocationOpt.jl/\npkg> add Comonicon","category":"page"},{"location":"#Usage","page":"Home","title":"Usage","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Download the allocationopt script. For example, using curl or wget. Make sure you use the raw file!\nMake the allocationopt script executable. ","category":"page"},{"location":"","page":"Home","title":"Home","text":"$ chmod +x allocationopt","category":"page"},{"location":"","page":"Home","title":"Home","text":"You can further simplify the use of this script by symlinking it to your .local/bin.","category":"page"},{"location":"","page":"Home","title":"Home","text":"For MacOS, symlink instead to /usr/local/bin.","category":"page"},{"location":"","page":"Home","title":"Home","text":"$ mkdir -p ~/.local/bin\n$ cd ~/.local/bin\n$ ln -s ~/projects/AllocationOpt.jl/scripts/allocationopt .  # Change to the path to the allocationopt script for you","category":"page"},{"location":"","page":"Home","title":"Home","text":"You should now be able to run the allocationopt script from anywhere!","category":"page"},{"location":"","page":"Home","title":"Home","text":"The optimiser queries the network subgraph data to optimize.","category":"page"},{"location":"","page":"Home","title":"Home","text":"We recommend making queries to the network subgraph served by your own indexer service. Alternatively, you can supply an API url to indexer_service_network_url from the decentralized gateway or hosted service.  To provide the network subgraph to the optimiser, set the indexer-service flag --serve-network-subgraph to true.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Populate your preferred lists (whitelist, blacklist, pinnedlist, frozenlist) into a CSV and remember its file path","category":"page"},{"location":"","page":"Home","title":"Home","text":"note: Note\n","category":"page"},{"location":"","page":"Home","title":"Home","text":"You can access the help for the optimiser by running the script with the --help flag. For example allocationopt --help.","category":"page"},{"location":"#Action-Queue","page":"Home","title":"Action Queue","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"This command requires a URL to the indexer management server and a URL to make graph network subgraph queries.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Run the allocationopt script with the actionqueue option.","category":"page"},{"location":"","page":"Home","title":"Home","text":"$ ./scripts/allocationopt actionqueue \"0x6ac85b9d834b51b14a7b0ed849bb5199e04c05c5\" 1 test/example.csv 50.0 28 30 0.3 http://localhost:18000 http://localhost:7600/network","category":"page"},{"location":"","page":"Home","title":"Home","text":"note: Note\nYou can access the help for the actionqueue option of the optimiser by running allocationopt actionqueue --help from your terminal.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The help contains more details about each of the arguments of the optimiser.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Requests from our tool are logged, and you can use the indexer CLI actions commands to check and approve actions.  We do NOT auto-approve actions on your behalf.","category":"page"},{"location":"#Indexing-Rules","page":"Home","title":"Indexing Rules","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"If you don't have the action queue set up yet, you can also run the optimiser by telling it to generate indexing rules. ","category":"page"},{"location":"","page":"Home","title":"Home","text":"warning: Warning\nUnder this setup, you must pay attention to the order in which you execute the rules.","category":"page"},{"location":"","page":"Home","title":"Home","text":"If you do not close existing allocations before opening new ones, you won't have enough capital to open your new allocations.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Run the allocationopt script with the rules option. The URL passed in should be an API URL","category":"page"},{"location":"","page":"Home","title":"Home","text":"$ ./scripts/allocationopt rules \"0x6ac85b9d834b51b14a7b0ed849bb5199e04c05c5\" 1 test/example.csv 50.0 28 25 0.3 http://localhost:7600/network","category":"page"},{"location":"","page":"Home","title":"Home","text":"note: Note\nYou can access the help for the rules option of the optimiser by running allocationopt rules --help from your terminal. The help contains more details about each of the arguments of the optimiser.","category":"page"},{"location":"#Bugs-and-Feature-Requests","page":"Home","title":"Bugs and Feature Requests","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Please submit bug reports/feature requests to our issue tracker.","category":"page"}]
}
