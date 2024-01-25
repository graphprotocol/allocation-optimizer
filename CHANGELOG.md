# Changelog

## [2.5.1](https://github.com/graphprotocol/allocation-optimizer/compare/v2.5.0...v2.5.1) (2024-01-25)


### Bug Fixes

* network subgraph FDS schema update ([2556c59](https://github.com/graphprotocol/allocation-optimizer/commit/2556c59342ebc0df353a14d5366336fb4227b9f3))

# [2.5.0](https://github.com/graphprotocol/allocation-optimizer/compare/v2.4.2...v2.5.0) (2023-09-27)


### Features

* support protocol_network config to actionqueue ([bba8173](https://github.com/graphprotocol/allocation-optimizer/commit/bba81730ba9d5eaaa8c6e7eda9fba8ba4e0dbd4d))
* support syncing_network filter in subgraph selection ([09a3b38](https://github.com/graphprotocol/allocation-optimizer/commit/09a3b3861c77c6b0448f70a9473a856e7036b698))

## [2.4.2](https://github.com/graphprotocol/allocation-optimizer/compare/v2.4.1...v2.4.2) (2023-09-07)


### Bug Fixes

* allow no current allocations ([4438cf5](https://github.com/graphprotocol/allocation-optimizer/commit/4438cf56851d9a4e154a60013e12b89b128bd644))
* N/A options for some k less than max_allocations ([8e4f8a0](https://github.com/graphprotocol/allocation-optimizer/commit/8e4f8a0b87a67ac115879b04d5f63d0912c4ed79))

## [2.4.1](https://github.com/graphprotocol/allocation-optimizer/compare/v2.4.0...v2.4.1) (2023-09-05)


### Bug Fixes

* linear indexing reward for network token issuance ([85d5ac7](https://github.com/graphprotocol/allocation-optimizer/commit/85d5ac7c50e66b98192c69e5e5e2a195cdc6a7af))

# [2.4.0](https://github.com/graphprotocol/allocation-optimizer/compare/v2.3.1...v2.4.0) (2023-05-11)


### Bug Fixes

* PGO computes optimal value for each sparsity ([2121343](https://github.com/graphprotocol/allocation-optimizer/commit/212134307b652f6b83bbd9096cd152e4ac2b55b2))


### Features

* PGO stops when it finds the same value twice ([d96592d](https://github.com/graphprotocol/allocation-optimizer/commit/d96592d2ce1658e6aeedd4cc6c0f010ce234c5d2))


### Performance Improvements

* Disable bounds checking on opt loops ([8b0ae3c](https://github.com/graphprotocol/allocation-optimizer/commit/8b0ae3c461c31fe3fd75a0a0311fce877f381182))

## [2.3.1](https://github.com/graphprotocol/allocation-optimizer/compare/v2.3.0...v2.3.1) (2023-05-03)


### Bug Fixes

* Correcting K for deniedAt filtering ([5840fbd](https://github.com/graphprotocol/allocation-optimizer/commit/5840fbdf1e7b8d9dbd3783f8c0f61c2d7ce012a5))

# [2.3.0](https://github.com/graphprotocol/allocation-optimizer/compare/v2.2.1...v2.3.0) (2023-04-27)


### Bug Fixes

* Filter out subgraphs with nonzero deniedAt ([219d4e0](https://github.com/graphprotocol/allocation-optimizer/commit/219d4e0930705e28e241e4d2e71169a0838dbb5e)), closes [#37](https://github.com/graphprotocol/allocation-optimizer/issues/37)


### Features

* deniedAt field accessor ([a37263b](https://github.com/graphprotocol/allocation-optimizer/commit/a37263bd9d193684423de28d37eb2846a794167b))
* Function gets indices of rewarded subgraphs ([113a86e](https://github.com/graphprotocol/allocation-optimizer/commit/113a86e6aea54ac07330cb8b6175a1919c37a503))
* Query deniedAt ([a7acaa4](https://github.com/graphprotocol/allocation-optimizer/commit/a7acaa4d4d451378f22aac46334120608033e5dc))

## [2.2.1](https://github.com/graphprotocol/allocation-optimizer/compare/v2.2.0...v2.2.1) (2023-04-27)


### Bug Fixes

* Pinnedlist behaviour fixed ([9cc96ba](https://github.com/graphprotocol/allocation-optimizer/commit/9cc96baf85d1be9e890d91f4bb2067e095d99ce2)), closes [#38](https://github.com/graphprotocol/allocation-optimizer/issues/38)

# [2.2.0](https://github.com/graphprotocol/allocation-optimizer/compare/v2.1.2...v2.2.0) (2023-04-27)


### Features

* Descriptive error when bad `readdir` ([66b264a](https://github.com/graphprotocol/allocation-optimizer/commit/66b264a00c878d9f545ebe552d7cab6b2e365d56))
* Warn users about not filtering deniedAt ([630f6b5](https://github.com/graphprotocol/allocation-optimizer/commit/630f6b581bdc3bd23dec00cfa78689da717751b0))

## [2.1.2](https://github.com/graphprotocol/allocation-optimizer/compare/v2.1.1...v2.1.2) (2023-04-24)


### Bug Fixes

* Pinned subgraphs are now whitelisted ([ddacc55](https://github.com/graphprotocol/allocation-optimizer/commit/ddacc555df08730b3fce04e83ce2aa06dc7a3b7e))

## [2.1.1](https://github.com/graphprotocol/allocation-optimizer/compare/v2.1.0...v2.1.1) (2023-04-17)


### Bug Fixes

* RoundDown when converting from BigFloat ([f8cce14](https://github.com/graphprotocol/allocation-optimizer/commit/f8cce14c26b046b2aebeae681ad57e8ef08b6e5c))

# [2.1.0](https://github.com/graphprotocol/allocation-optimizer/compare/v2.0.1...v2.1.0) (2023-04-17)


### Bug Fixes

* Allow for views ([2476317](https://github.com/graphprotocol/allocation-optimizer/commit/2476317597c1de2073142c42c0b0a9915982a8f4))
* Minimisation needs to use negative profit ([470a72e](https://github.com/graphprotocol/allocation-optimizer/commit/470a72e64c4b0358eb264858d49081adf795349b))


### Features

* Add opt_mode option to the config ([0b4534a](https://github.com/graphprotocol/allocation-optimizer/commit/0b4534aae0f784a87eca1e162adfb0c3d1b01427))
* Add slower but more accurate "optimal" path ([1629de7](https://github.com/graphprotocol/allocation-optimizer/commit/1629de7f49cec83a117af853e626cbb8e77e942b))
* Add warning for using optimal path ([0ced47f](https://github.com/graphprotocol/allocation-optimizer/commit/0ced47f3b3a10741073d845924cf7727ab3f3f62))
* Analytic optimisation backed by SemioticOpt ([33d049a](https://github.com/graphprotocol/allocation-optimizer/commit/33d049a4864085ddf86b9b4b7c8d2c0f51de27db))
* Indexing reward computed for ixs ([7e651f2](https://github.com/graphprotocol/allocation-optimizer/commit/7e651f24b4f611a38823ba86d948204828f5621b))
* Optimize call dispatches on opt_mode ([3a1b116](https://github.com/graphprotocol/allocation-optimizer/commit/3a1b1164c03bd9e1c9165e33a8670087b31ff8bb))

## [2.0.1](https://github.com/graphprotocol/allocation-optimizer/compare/v2.0.0...v2.0.1) (2023-04-17)


### Bug Fixes

* Increased precision of simplex projection ([53c4aef](https://github.com/graphprotocol/allocation-optimizer/commit/53c4aef94e33eef96f50791da2530e91593ec546)), closes [#32](https://github.com/graphprotocol/allocation-optimizer/issues/32)

# [2.0.0](https://github.com/graphprotocol/allocation-optimizer/compare/v1.8.0...v2.0.0) (2023-04-14)


### Bug Fixes

* admonition rendering ([023cef7](https://github.com/graphprotocol/allocation-optimizer/commit/023cef7df55c5ca71ac723311830acca48b4e4ad))
* avilable stake query and calculation ([bb49f3d](https://github.com/graphprotocol/allocation-optimizer/commit/bb49f3db4a761dab9ea83ae5b5bb07b903f263f5))
* broken test due to types ([3acb8f4](https://github.com/graphprotocol/allocation-optimizer/commit/3acb8f489b8620fe5ccf6998eaab0ac4a7a98566))
* documentation ([3944d43](https://github.com/graphprotocol/allocation-optimizer/commit/3944d43689c01134b901bfda5c6398917c5e6fb3))
* documentation admonitions ([a37a7f2](https://github.com/graphprotocol/allocation-optimizer/commit/a37a7f23af751d3f4cc975a4c86776cff9ab0f28))
* Ensure that max_allocations < num_subgraphs ([272d1f5](https://github.com/graphprotocol/allocation-optimizer/commit/272d1f5b76ad7ec4a20df18f823f46ab5525a967))
* Filter out subgraphs with less than minsignal ([09392e4](https://github.com/graphprotocol/allocation-optimizer/commit/09392e47cf40d8d4f2f73e0c811e580589b1135c))
* floor instead of round for final allocation amount ([c9273da](https://github.com/graphprotocol/allocation-optimizer/commit/c9273dabf187dc8a7511c87bbac0080edbe50a6b))
* format ([c78bc6d](https://github.com/graphprotocol/allocation-optimizer/commit/c78bc6dcdb681fb63812dfb355dace8cb44f8826))
* format actionQueue alloctionAmount ([2f6c527](https://github.com/graphprotocol/allocation-optimizer/commit/2f6c5279c133538f23e342cfd24bd23f6e5031e2))
* format grt ([cc99310](https://github.com/graphprotocol/allocation-optimizer/commit/cc993107acda9a29de822b9d9ffc14c12178bc3e))
* graphql mutations ([d306ba7](https://github.com/graphprotocol/allocation-optimizer/commit/d306ba781df71117c3d578778b2e1e655ac6d818))
* halpern iteration ([b045628](https://github.com/graphprotocol/allocation-optimizer/commit/b045628521be96e4a157f831a045af784b108369))
* Handle case with no frozenlist ([9838536](https://github.com/graphprotocol/allocation-optimizer/commit/9838536db1f51a1fcde0510bbea76d0963f36d15))
* lipschitz constant step size ([f3c6217](https://github.com/graphprotocol/allocation-optimizer/commit/f3c62177a214a489c3fa61efc8621fa256c736d7))
* network subgraph filtering for optimizing over time ([6492f6e](https://github.com/graphprotocol/allocation-optimizer/commit/6492f6ef833785f98b096db21003f1c967a1a612))
* remove build for Julia nightly ([7d38992](https://github.com/graphprotocol/allocation-optimizer/commit/7d38992179e931745a86b8cbf98bcc071cf684f6))
* remove network id from user input ([e467d77](https://github.com/graphprotocol/allocation-optimizer/commit/e467d7737bfbdef22661cef5ac3d37a34c374428))
* rounding to avoid !capacity contract error ([b16af80](https://github.com/graphprotocol/allocation-optimizer/commit/b16af80b2a03466f54929bf8f88ef18267df1a35))
* stake amount include lockedTokens ([a74db38](https://github.com/graphprotocol/allocation-optimizer/commit/a74db38b97304a8a5a2e2ce6fe315c01edb553bc))
* strategy can't allocate too much stake ([093bd28](https://github.com/graphprotocol/allocation-optimizer/commit/093bd280d3a9eedb6d762e571e684f7c5b8598b9))
* Test reflects new iquery output ([557df23](https://github.com/graphprotocol/allocation-optimizer/commit/557df2386fa531298e6abe8de9bd9e01676d71d9))
* test update to avoid signal changes in network ([9ed57c0](https://github.com/graphprotocol/allocation-optimizer/commit/9ed57c0389104a65d9492daf23a183a28606e56e))
* typo and correct formatting ([988a7ef](https://github.com/graphprotocol/allocation-optimizer/commit/988a7efaa2a667d07558a513533bc6ea71a75890))


### Features

* actionqueue patch - allocate ([53378d5](https://github.com/graphprotocol/allocation-optimizer/commit/53378d5360803bf72c6c66428b3ea46d5c6c7685))
* actionqueue patch - reallocate ([95d9ab1](https://github.com/graphprotocol/allocation-optimizer/commit/95d9ab1bdf10d139432055efca7e767a97cbc88a))
* actionqueue patch - unallocate ([c6baa43](https://github.com/graphprotocol/allocation-optimizer/commit/c6baa432b07c5edffa618f4a4af7b80c74cb87bb))
* added hypotheticalstake command, empty CSV error handle ([acccd71](https://github.com/graphprotocol/allocation-optimizer/commit/acccd71493e8eae121e4470636e573c0245eaf04))
* Adjustable eta (hardcoded) ([6d314ae](https://github.com/graphprotocol/allocation-optimizer/commit/6d314aec435f3930db673bee16c0c7327cba66e9))
* adjustive step size ([eed5d93](https://github.com/graphprotocol/allocation-optimizer/commit/eed5d93f4a824e6672c576c5769d94d718bf043e))
* Allocatable subgraphs view ([863d939](https://github.com/graphprotocol/allocation-optimizer/commit/863d9397ee52bdf1d8049b7a67b364f9358c746a))
* Allocation accessor ([d3b8a35](https://github.com/graphprotocol/allocation-optimizer/commit/d3b8a35bbc3c46e3eb5a1e808a84732f090469af))
* allocation profit and APR script command ([61c9169](https://github.com/graphprotocol/allocation-optimizer/commit/61c91691927cda6ae44d084cb219347371200ec4))
* alternative script for generating indexing rules ([4084c44](https://github.com/graphprotocol/allocation-optimizer/commit/4084c449d6e449dcb551b21395105c759b76b4e6))
* Analytic optimisation ([3b8ead8](https://github.com/graphprotocol/allocation-optimizer/commit/3b8ead851434820bb7c3a694b4626d3290936d10))
* automatically lowercase indexer id from checksum addr ([ff1b43d](https://github.com/graphprotocol/allocation-optimizer/commit/ff1b43ddea8f0911424c669573ef56a4a80da0f8))
* best profit and index on nonzeros ([c5152f6](https://github.com/graphprotocol/allocation-optimizer/commit/c5152f647f18b8816c77ddf96d613f66aa950ad5))
* build json data object ([0fad9ad](https://github.com/graphprotocol/allocation-optimizer/commit/0fad9ad6a6aaca5566a34910f9ecb429b14e4a9a))
* Compute frozen stake ([01ed4a2](https://github.com/graphprotocol/allocation-optimizer/commit/01ed4a2d0088e6f2af7d5e30ffd93705e490f5cd))
* Compute issued tokens and update main script ([d3bd1a0](https://github.com/graphprotocol/allocation-optimizer/commit/d3bd1a09795db5fb4c6de7179374d2b96861ff81))
* compute pinned allocation amount ([7085cdf](https://github.com/graphprotocol/allocation-optimizer/commit/7085cdfc0d55a2225ac93663103eddb2a9e2f798))
* Compute profit using gas ([c0c28e7](https://github.com/graphprotocol/allocation-optimizer/commit/c0c28e7254f524210dc59472fe2156abdc2e02ca))
* configurable network subgraph endpoint ([48c6d1c](https://github.com/graphprotocol/allocation-optimizer/commit/48c6d1c84b358780127052d5e05c04880101dec6))
* Convert all tables together ([50fab0e](https://github.com/graphprotocol/allocation-optimizer/commit/50fab0ef0109a14a94dc3f0ab41f347d7a81540b))
* Convert allocation table to GRT type ([d62a89a](https://github.com/graphprotocol/allocation-optimizer/commit/d62a89a3de5f7254954b99736b8ce14226fb1815))
* Convert indexer table to GRT type ([19bd0ac](https://github.com/graphprotocol/allocation-optimizer/commit/19bd0ac70756d176382a7d7afa461051e4d97d66))
* Convert network table to GRT type ([a405952](https://github.com/graphprotocol/allocation-optimizer/commit/a405952732d4f46c4c845cd437c463e11819fe39))
* Convert queried data to GRT ([78917a8](https://github.com/graphprotocol/allocation-optimizer/commit/78917a8e0a357a1ecc01a14f0ca8d8d2d44e38d3))
* Convert subgraph table to GRT type ([c26b503](https://github.com/graphprotocol/allocation-optimizer/commit/c26b503b965fd45411b0cec315db282e2d380365))
* Correct types after querying ([411a11f](https://github.com/graphprotocol/allocation-optimizer/commit/411a11fb69ca8a6c21a879ca8fb75b36c6c14da9))
* data function routes via dispatch ([2ee0624](https://github.com/graphprotocol/allocation-optimizer/commit/2ee0624f6714976b455559401413fab395440d30))
* Delegation accessor ([f3841ec](https://github.com/graphprotocol/allocation-optimizer/commit/f3841ec071aba678ce06f67ee6e6689e657fccb4))
* Don't hold onto allocations table ([8a4c86d](https://github.com/graphprotocol/allocation-optimizer/commit/8a4c86d4c1487a9b62324836489d5213c86f6f3d))
* Ensure id is in the config ([3240c2a](https://github.com/graphprotocol/allocation-optimizer/commit/3240c2aa58fa4691c88a2ea556b18b88bc8d76ba))
* execute mode ([7b8342d](https://github.com/graphprotocol/allocation-optimizer/commit/7b8342de263b7356b1e1fd061332266af8ee8205))
* execution mode - none, just output results in json ([7f04844](https://github.com/graphprotocol/allocation-optimizer/commit/7f04844dee2acf5ff992d8cbbd91ccd5f68ee23e))
* Function to get signal on subgraph ([3e0b5f6](https://github.com/graphprotocol/allocation-optimizer/commit/3e0b5f6f150aac479a32bc61ef9a1f3f4108cf0f))
* group unique values function ([877e834](https://github.com/graphprotocol/allocation-optimizer/commit/877e834ba9041cd9c6eb557a75e1e232c66b1894))
* Helper function for a gql allocation query ([1c479e0](https://github.com/graphprotocol/allocation-optimizer/commit/1c479e0ce5760a6d2cb59e399b438e4ae08b366f))
* Helper function for a gql indexer query ([01cc0c9](https://github.com/graphprotocol/allocation-optimizer/commit/01cc0c999ebb2f4968d64eb3a48e8c015ad6392a))
* Helper function for a gql network query ([609320b](https://github.com/graphprotocol/allocation-optimizer/commit/609320b9767cdbd2e82914309e282967bbdf524a))
* Helper function for a gql subgraph query ([b3d93ea](https://github.com/graphprotocol/allocation-optimizer/commit/b3d93ea124c83c8656b9e31371e2c637fd24cadf))
* Helper function for save names of data CSVs ([0c9ecfd](https://github.com/graphprotocol/allocation-optimizer/commit/0c9ecfd84993a472b21b435c1aeb92e3a2374eec))
* Indexer's staked tokens ([51cf915](https://github.com/graphprotocol/allocation-optimizer/commit/51cf91517169b9c2fecdfbd4b5ceb7cb9f17a38a))
* Indexing reward ([1ac9da2](https://github.com/graphprotocol/allocation-optimizer/commit/1ac9da26d31c55f126a59438891a0b5d966db3b2))
* ipfshash accessor for allocations ([a9d0f8a](https://github.com/graphprotocol/allocation-optimizer/commit/a9d0f8a20f82b1906267e09ff28210cd29b1a2db))
* K-sparse optimisation ([315495e](https://github.com/graphprotocol/allocation-optimizer/commit/315495e28de6107d77e3d6b0b6a70830489eb49a))
* Locked tokens accessor ([1ac5fae](https://github.com/graphprotocol/allocation-optimizer/commit/1ac5fae23a2ce663ff6c7752f67092617774a717))
* Main function computes stake ([3c26a5f](https://github.com/graphprotocol/allocation-optimizer/commit/3c26a5fac7871b23d17e49feb183144df435f8ea))
* Network accessors ([ca38e6a](https://github.com/graphprotocol/allocation-optimizer/commit/ca38e6ad79a16ae359f30f43c1ec58b2cd325efe))
* Optimisation using PGD ([cdd0ebb](https://github.com/graphprotocol/allocation-optimizer/commit/cdd0ebbda2cfa1ac1e24869da059e77ea06cc3dd))
* optimise over time ([fd62323](https://github.com/graphprotocol/allocation-optimizer/commit/fd62323de44e15ddb39e95e9b88ed5535c18a317))
* Optimising over gas in parallel ([ece2d73](https://github.com/graphprotocol/allocation-optimizer/commit/ece2d73d83d0ee6f30cb8ad50d0aab1888fba61f))
* optimizesummary with json output ([1e2a62f](https://github.com/graphprotocol/allocation-optimizer/commit/1e2a62f0ae7870b8743754505572c48e9619b8f8))
* pinnedlist support ([2e53a45](https://github.com/graphprotocol/allocation-optimizer/commit/2e53a4521f9efb9b50dc22dd0f9360692e4ebb5e))
* Projected gradient descent ([34886b7](https://github.com/graphprotocol/allocation-optimizer/commit/34886b71275b5c61fd3bc6f642731c663deb57c6))
* query allocation id ([e7834f7](https://github.com/graphprotocol/allocation-optimizer/commit/e7834f787bc52e16eda1c95ba72f4c3dde9fa293))
* Query data from GQL endpoint ([cc164e1](https://github.com/graphprotocol/allocation-optimizer/commit/cc164e1056210e327503d46a4b6f2d90ad021596))
* Query only the indexer we care about ([a1f8e9c](https://github.com/graphprotocol/allocation-optimizer/commit/a1f8e9c165c7f3ab8716f51426adf33f940a6383))
* read config from TOML ([f34f286](https://github.com/graphprotocol/allocation-optimizer/commit/f34f2861ea35d83d86e3a3a5a38bdb63673f64ee))
* Read queried data from CSVs ([7ef33fe](https://github.com/graphprotocol/allocation-optimizer/commit/7ef33fe806d3236a604831cc257f367a1558a6a0))
* Reduce number of queries ([aebb58d](https://github.com/graphprotocol/allocation-optimizer/commit/aebb58da8cc683ae80e21770e3467fc85db070d5))
* Save allocations to CSV again ([8a4b59b](https://github.com/graphprotocol/allocation-optimizer/commit/8a4b59bbf88a4c1d9cd2254d17e624a3f4ca039e))
* scalar indexing rewards ([40be5a1](https://github.com/graphprotocol/allocation-optimizer/commit/40be5a1e5ab920f329375fc08f5ee55fa64a5536))
* scalar profit into matrix ([97f6e24](https://github.com/graphprotocol/allocation-optimizer/commit/97f6e24e23c9078f41fd12693eeec58bae630b00))
* Set defaults values for config ([4f39de3](https://github.com/graphprotocol/allocation-optimizer/commit/4f39de3d9c2f821ecc109fb1a86b78574c3fa892))
* sort profits ([4eb6136](https://github.com/graphprotocol/allocation-optimizer/commit/4eb6136d11a2a54f1871f50c9fec08f8c7427f33))
* Staked tokens on each subgraph ([bd13630](https://github.com/graphprotocol/allocation-optimizer/commit/bd13630368c5c38d9aa95a66e1eed7526bf902af))
* subgraph ipfshash accessor ([61d637b](https://github.com/graphprotocol/allocation-optimizer/commit/61d637bf4e947a0d873c361eb5c2f0ff68d88dec))
* Subtract indexer from subgraph total ([6878ffb](https://github.com/graphprotocol/allocation-optimizer/commit/6878ffb8232aa5f051995e8cb63bf9d9722b2e67))
* Updating to match latest version of ActionQueue ([bfc5003](https://github.com/graphprotocol/allocation-optimizer/commit/bfc5003ac82cce079911adce5c1616bb650b7192))
* use allocation table in execution ([81f0d1d](https://github.com/graphprotocol/allocation-optimizer/commit/81f0d1d0009b0d4eac511dd27f4a1e5264833aaa))
* user config for execution_mode and indexer_url ([abe838a](https://github.com/graphprotocol/allocation-optimizer/commit/abe838a6edd6350785a7d42f7cb4377e170698b7))
* user specified num_reported_options ([7ff5147](https://github.com/graphprotocol/allocation-optimizer/commit/7ff51474215d5519dd4e1f84e11174e69e1ba456))
* UX and performance improvements ([7d80297](https://github.com/graphprotocol/allocation-optimizer/commit/7d80297a37b69cb992b43cdf67a9e4c13fd71154))
* Verbose mode ([94e5918](https://github.com/graphprotocol/allocation-optimizer/commit/94e5918ba7fbe16a3d7b93bed506c748eadb3e81))
* View unfrozen subgraphs ([1babd1e](https://github.com/graphprotocol/allocation-optimizer/commit/1babd1eafe3e34e12288312436e881e481857a82))
* write json output ([8d73597](https://github.com/graphprotocol/allocation-optimizer/commit/8d73597cee7d7b67762913845816d42a281e37e2))
* Write tables to path from config ([8f6b4d6](https://github.com/graphprotocol/allocation-optimizer/commit/8f6b4d63e2abe975a1cec9f0a27fd282911e03ea))


### BREAKING CHANGES

* Config driven workflow breaks v1 API.
Various performance improvements.

# [1.9.0](https://github.com/graphprotocol/allocation-optimizer/compare/v1.8.0...v1.9.0) (2023-04-13)


### Bug Fixes

* admonition rendering ([023cef7](https://github.com/graphprotocol/allocation-optimizer/commit/023cef7df55c5ca71ac723311830acca48b4e4ad))
* avilable stake query and calculation ([bb49f3d](https://github.com/graphprotocol/allocation-optimizer/commit/bb49f3db4a761dab9ea83ae5b5bb07b903f263f5))
* broken test due to types ([3acb8f4](https://github.com/graphprotocol/allocation-optimizer/commit/3acb8f489b8620fe5ccf6998eaab0ac4a7a98566))
* documentation ([3944d43](https://github.com/graphprotocol/allocation-optimizer/commit/3944d43689c01134b901bfda5c6398917c5e6fb3))
* documentation admonitions ([a37a7f2](https://github.com/graphprotocol/allocation-optimizer/commit/a37a7f23af751d3f4cc975a4c86776cff9ab0f28))
* Ensure that max_allocations < num_subgraphs ([272d1f5](https://github.com/graphprotocol/allocation-optimizer/commit/272d1f5b76ad7ec4a20df18f823f46ab5525a967))
* Filter out subgraphs with less than minsignal ([09392e4](https://github.com/graphprotocol/allocation-optimizer/commit/09392e47cf40d8d4f2f73e0c811e580589b1135c))
* floor instead of round for final allocation amount ([c9273da](https://github.com/graphprotocol/allocation-optimizer/commit/c9273dabf187dc8a7511c87bbac0080edbe50a6b))
* format ([c78bc6d](https://github.com/graphprotocol/allocation-optimizer/commit/c78bc6dcdb681fb63812dfb355dace8cb44f8826))
* format actionQueue alloctionAmount ([2f6c527](https://github.com/graphprotocol/allocation-optimizer/commit/2f6c5279c133538f23e342cfd24bd23f6e5031e2))
* format grt ([cc99310](https://github.com/graphprotocol/allocation-optimizer/commit/cc993107acda9a29de822b9d9ffc14c12178bc3e))
* graphql mutations ([d306ba7](https://github.com/graphprotocol/allocation-optimizer/commit/d306ba781df71117c3d578778b2e1e655ac6d818))
* halpern iteration ([b045628](https://github.com/graphprotocol/allocation-optimizer/commit/b045628521be96e4a157f831a045af784b108369))
* Handle case with no frozenlist ([9838536](https://github.com/graphprotocol/allocation-optimizer/commit/9838536db1f51a1fcde0510bbea76d0963f36d15))
* lipschitz constant step size ([f3c6217](https://github.com/graphprotocol/allocation-optimizer/commit/f3c62177a214a489c3fa61efc8621fa256c736d7))
* network subgraph filtering for optimizing over time ([6492f6e](https://github.com/graphprotocol/allocation-optimizer/commit/6492f6ef833785f98b096db21003f1c967a1a612))
* remove build for Julia nightly ([7d38992](https://github.com/graphprotocol/allocation-optimizer/commit/7d38992179e931745a86b8cbf98bcc071cf684f6))
* remove network id from user input ([e467d77](https://github.com/graphprotocol/allocation-optimizer/commit/e467d7737bfbdef22661cef5ac3d37a34c374428))
* rounding to avoid !capacity contract error ([b16af80](https://github.com/graphprotocol/allocation-optimizer/commit/b16af80b2a03466f54929bf8f88ef18267df1a35))
* stake amount include lockedTokens ([a74db38](https://github.com/graphprotocol/allocation-optimizer/commit/a74db38b97304a8a5a2e2ce6fe315c01edb553bc))
* strategy can't allocate too much stake ([093bd28](https://github.com/graphprotocol/allocation-optimizer/commit/093bd280d3a9eedb6d762e571e684f7c5b8598b9))
* Test reflects new iquery output ([557df23](https://github.com/graphprotocol/allocation-optimizer/commit/557df2386fa531298e6abe8de9bd9e01676d71d9))
* test update to avoid signal changes in network ([9ed57c0](https://github.com/graphprotocol/allocation-optimizer/commit/9ed57c0389104a65d9492daf23a183a28606e56e))
* typo and correct formatting ([988a7ef](https://github.com/graphprotocol/allocation-optimizer/commit/988a7efaa2a667d07558a513533bc6ea71a75890))


### Features

* actionqueue patch - allocate ([53378d5](https://github.com/graphprotocol/allocation-optimizer/commit/53378d5360803bf72c6c66428b3ea46d5c6c7685))
* actionqueue patch - reallocate ([95d9ab1](https://github.com/graphprotocol/allocation-optimizer/commit/95d9ab1bdf10d139432055efca7e767a97cbc88a))
* actionqueue patch - unallocate ([c6baa43](https://github.com/graphprotocol/allocation-optimizer/commit/c6baa432b07c5edffa618f4a4af7b80c74cb87bb))
* added hypotheticalstake command, empty CSV error handle ([acccd71](https://github.com/graphprotocol/allocation-optimizer/commit/acccd71493e8eae121e4470636e573c0245eaf04))
* Adjustable eta (hardcoded) ([6d314ae](https://github.com/graphprotocol/allocation-optimizer/commit/6d314aec435f3930db673bee16c0c7327cba66e9))
* adjustive step size ([eed5d93](https://github.com/graphprotocol/allocation-optimizer/commit/eed5d93f4a824e6672c576c5769d94d718bf043e))
* Allocatable subgraphs view ([863d939](https://github.com/graphprotocol/allocation-optimizer/commit/863d9397ee52bdf1d8049b7a67b364f9358c746a))
* Allocation accessor ([d3b8a35](https://github.com/graphprotocol/allocation-optimizer/commit/d3b8a35bbc3c46e3eb5a1e808a84732f090469af))
* allocation profit and APR script command ([61c9169](https://github.com/graphprotocol/allocation-optimizer/commit/61c91691927cda6ae44d084cb219347371200ec4))
* alternative script for generating indexing rules ([4084c44](https://github.com/graphprotocol/allocation-optimizer/commit/4084c449d6e449dcb551b21395105c759b76b4e6))
* Analytic optimisation ([3b8ead8](https://github.com/graphprotocol/allocation-optimizer/commit/3b8ead851434820bb7c3a694b4626d3290936d10))
* automatically lowercase indexer id from checksum addr ([ff1b43d](https://github.com/graphprotocol/allocation-optimizer/commit/ff1b43ddea8f0911424c669573ef56a4a80da0f8))
* best profit and index on nonzeros ([c5152f6](https://github.com/graphprotocol/allocation-optimizer/commit/c5152f647f18b8816c77ddf96d613f66aa950ad5))
* build json data object ([0fad9ad](https://github.com/graphprotocol/allocation-optimizer/commit/0fad9ad6a6aaca5566a34910f9ecb429b14e4a9a))
* Compute frozen stake ([01ed4a2](https://github.com/graphprotocol/allocation-optimizer/commit/01ed4a2d0088e6f2af7d5e30ffd93705e490f5cd))
* Compute issued tokens and update main script ([d3bd1a0](https://github.com/graphprotocol/allocation-optimizer/commit/d3bd1a09795db5fb4c6de7179374d2b96861ff81))
* compute pinned allocation amount ([7085cdf](https://github.com/graphprotocol/allocation-optimizer/commit/7085cdfc0d55a2225ac93663103eddb2a9e2f798))
* Compute profit using gas ([c0c28e7](https://github.com/graphprotocol/allocation-optimizer/commit/c0c28e7254f524210dc59472fe2156abdc2e02ca))
* configurable network subgraph endpoint ([48c6d1c](https://github.com/graphprotocol/allocation-optimizer/commit/48c6d1c84b358780127052d5e05c04880101dec6))
* Convert all tables together ([50fab0e](https://github.com/graphprotocol/allocation-optimizer/commit/50fab0ef0109a14a94dc3f0ab41f347d7a81540b))
* Convert allocation table to GRT type ([d62a89a](https://github.com/graphprotocol/allocation-optimizer/commit/d62a89a3de5f7254954b99736b8ce14226fb1815))
* Convert indexer table to GRT type ([19bd0ac](https://github.com/graphprotocol/allocation-optimizer/commit/19bd0ac70756d176382a7d7afa461051e4d97d66))
* Convert network table to GRT type ([a405952](https://github.com/graphprotocol/allocation-optimizer/commit/a405952732d4f46c4c845cd437c463e11819fe39))
* Convert queried data to GRT ([78917a8](https://github.com/graphprotocol/allocation-optimizer/commit/78917a8e0a357a1ecc01a14f0ca8d8d2d44e38d3))
* Convert subgraph table to GRT type ([c26b503](https://github.com/graphprotocol/allocation-optimizer/commit/c26b503b965fd45411b0cec315db282e2d380365))
* Correct types after querying ([411a11f](https://github.com/graphprotocol/allocation-optimizer/commit/411a11fb69ca8a6c21a879ca8fb75b36c6c14da9))
* data function routes via dispatch ([2ee0624](https://github.com/graphprotocol/allocation-optimizer/commit/2ee0624f6714976b455559401413fab395440d30))
* Delegation accessor ([f3841ec](https://github.com/graphprotocol/allocation-optimizer/commit/f3841ec071aba678ce06f67ee6e6689e657fccb4))
* Don't hold onto allocations table ([8a4c86d](https://github.com/graphprotocol/allocation-optimizer/commit/8a4c86d4c1487a9b62324836489d5213c86f6f3d))
* Ensure id is in the config ([3240c2a](https://github.com/graphprotocol/allocation-optimizer/commit/3240c2aa58fa4691c88a2ea556b18b88bc8d76ba))
* execute mode ([7b8342d](https://github.com/graphprotocol/allocation-optimizer/commit/7b8342de263b7356b1e1fd061332266af8ee8205))
* execution mode - none, just output results in json ([7f04844](https://github.com/graphprotocol/allocation-optimizer/commit/7f04844dee2acf5ff992d8cbbd91ccd5f68ee23e))
* Function to get signal on subgraph ([3e0b5f6](https://github.com/graphprotocol/allocation-optimizer/commit/3e0b5f6f150aac479a32bc61ef9a1f3f4108cf0f))
* group unique values function ([877e834](https://github.com/graphprotocol/allocation-optimizer/commit/877e834ba9041cd9c6eb557a75e1e232c66b1894))
* Helper function for a gql allocation query ([1c479e0](https://github.com/graphprotocol/allocation-optimizer/commit/1c479e0ce5760a6d2cb59e399b438e4ae08b366f))
* Helper function for a gql indexer query ([01cc0c9](https://github.com/graphprotocol/allocation-optimizer/commit/01cc0c999ebb2f4968d64eb3a48e8c015ad6392a))
* Helper function for a gql network query ([609320b](https://github.com/graphprotocol/allocation-optimizer/commit/609320b9767cdbd2e82914309e282967bbdf524a))
* Helper function for a gql subgraph query ([b3d93ea](https://github.com/graphprotocol/allocation-optimizer/commit/b3d93ea124c83c8656b9e31371e2c637fd24cadf))
* Helper function for save names of data CSVs ([0c9ecfd](https://github.com/graphprotocol/allocation-optimizer/commit/0c9ecfd84993a472b21b435c1aeb92e3a2374eec))
* Indexer's staked tokens ([51cf915](https://github.com/graphprotocol/allocation-optimizer/commit/51cf91517169b9c2fecdfbd4b5ceb7cb9f17a38a))
* Indexing reward ([1ac9da2](https://github.com/graphprotocol/allocation-optimizer/commit/1ac9da26d31c55f126a59438891a0b5d966db3b2))
* ipfshash accessor for allocations ([a9d0f8a](https://github.com/graphprotocol/allocation-optimizer/commit/a9d0f8a20f82b1906267e09ff28210cd29b1a2db))
* K-sparse optimisation ([315495e](https://github.com/graphprotocol/allocation-optimizer/commit/315495e28de6107d77e3d6b0b6a70830489eb49a))
* Locked tokens accessor ([1ac5fae](https://github.com/graphprotocol/allocation-optimizer/commit/1ac5fae23a2ce663ff6c7752f67092617774a717))
* Main function computes stake ([3c26a5f](https://github.com/graphprotocol/allocation-optimizer/commit/3c26a5fac7871b23d17e49feb183144df435f8ea))
* Network accessors ([ca38e6a](https://github.com/graphprotocol/allocation-optimizer/commit/ca38e6ad79a16ae359f30f43c1ec58b2cd325efe))
* Optimisation using PGD ([cdd0ebb](https://github.com/graphprotocol/allocation-optimizer/commit/cdd0ebbda2cfa1ac1e24869da059e77ea06cc3dd))
* optimise over time ([fd62323](https://github.com/graphprotocol/allocation-optimizer/commit/fd62323de44e15ddb39e95e9b88ed5535c18a317))
* Optimising over gas in parallel ([ece2d73](https://github.com/graphprotocol/allocation-optimizer/commit/ece2d73d83d0ee6f30cb8ad50d0aab1888fba61f))
* optimizesummary with json output ([1e2a62f](https://github.com/graphprotocol/allocation-optimizer/commit/1e2a62f0ae7870b8743754505572c48e9619b8f8))
* pinnedlist support ([2e53a45](https://github.com/graphprotocol/allocation-optimizer/commit/2e53a4521f9efb9b50dc22dd0f9360692e4ebb5e))
* Projected gradient descent ([34886b7](https://github.com/graphprotocol/allocation-optimizer/commit/34886b71275b5c61fd3bc6f642731c663deb57c6))
* query allocation id ([e7834f7](https://github.com/graphprotocol/allocation-optimizer/commit/e7834f787bc52e16eda1c95ba72f4c3dde9fa293))
* Query data from GQL endpoint ([cc164e1](https://github.com/graphprotocol/allocation-optimizer/commit/cc164e1056210e327503d46a4b6f2d90ad021596))
* Query only the indexer we care about ([a1f8e9c](https://github.com/graphprotocol/allocation-optimizer/commit/a1f8e9c165c7f3ab8716f51426adf33f940a6383))
* read config from TOML ([f34f286](https://github.com/graphprotocol/allocation-optimizer/commit/f34f2861ea35d83d86e3a3a5a38bdb63673f64ee))
* Read queried data from CSVs ([7ef33fe](https://github.com/graphprotocol/allocation-optimizer/commit/7ef33fe806d3236a604831cc257f367a1558a6a0))
* Reduce number of queries ([aebb58d](https://github.com/graphprotocol/allocation-optimizer/commit/aebb58da8cc683ae80e21770e3467fc85db070d5))
* Save allocations to CSV again ([8a4b59b](https://github.com/graphprotocol/allocation-optimizer/commit/8a4b59bbf88a4c1d9cd2254d17e624a3f4ca039e))
* scalar indexing rewards ([40be5a1](https://github.com/graphprotocol/allocation-optimizer/commit/40be5a1e5ab920f329375fc08f5ee55fa64a5536))
* scalar profit into matrix ([97f6e24](https://github.com/graphprotocol/allocation-optimizer/commit/97f6e24e23c9078f41fd12693eeec58bae630b00))
* Set defaults values for config ([4f39de3](https://github.com/graphprotocol/allocation-optimizer/commit/4f39de3d9c2f821ecc109fb1a86b78574c3fa892))
* sort profits ([4eb6136](https://github.com/graphprotocol/allocation-optimizer/commit/4eb6136d11a2a54f1871f50c9fec08f8c7427f33))
* Staked tokens on each subgraph ([bd13630](https://github.com/graphprotocol/allocation-optimizer/commit/bd13630368c5c38d9aa95a66e1eed7526bf902af))
* subgraph ipfshash accessor ([61d637b](https://github.com/graphprotocol/allocation-optimizer/commit/61d637bf4e947a0d873c361eb5c2f0ff68d88dec))
* Subtract indexer from subgraph total ([6878ffb](https://github.com/graphprotocol/allocation-optimizer/commit/6878ffb8232aa5f051995e8cb63bf9d9722b2e67))
* Updating to match latest version of ActionQueue ([bfc5003](https://github.com/graphprotocol/allocation-optimizer/commit/bfc5003ac82cce079911adce5c1616bb650b7192))
* use allocation table in execution ([81f0d1d](https://github.com/graphprotocol/allocation-optimizer/commit/81f0d1d0009b0d4eac511dd27f4a1e5264833aaa))
* user config for execution_mode and indexer_url ([abe838a](https://github.com/graphprotocol/allocation-optimizer/commit/abe838a6edd6350785a7d42f7cb4377e170698b7))
* user specified num_reported_options ([7ff5147](https://github.com/graphprotocol/allocation-optimizer/commit/7ff51474215d5519dd4e1f84e11174e69e1ba456))
* Verbose mode ([94e5918](https://github.com/graphprotocol/allocation-optimizer/commit/94e5918ba7fbe16a3d7b93bed506c748eadb3e81))
* View unfrozen subgraphs ([1babd1e](https://github.com/graphprotocol/allocation-optimizer/commit/1babd1eafe3e34e12288312436e881e481857a82))
* write json output ([8d73597](https://github.com/graphprotocol/allocation-optimizer/commit/8d73597cee7d7b67762913845816d42a281e37e2))
* Write tables to path from config ([8f6b4d6](https://github.com/graphprotocol/allocation-optimizer/commit/8f6b4d63e2abe975a1cec9f0a27fd282911e03ea))
