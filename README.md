# token-prices DApp

```
Cartesi Rollups version: 0.8.x
```

This DApp exemplifies two ways to feed token prices to a Cartesi Rollups DApp. The DApp receives the prices of the tokens as Input and generates a notice with the information received. Two contracts provide the prices in two ways, one using [Chainlink](https://docs.chain.link/) and the other using [Uniswap](https://uniswap.org/). Chainlink is a Decentralized Oracle Network (DON) that can feed the DApp with real-world prices, like the ETH price in dollars. It does that through Aggregators that observe and aggregate the price of some token. Uniswap, on the other hand, is a decentralized protocol for swapping ERC20 tokens, so it has pools of pairs of ERC20 tokens and provides the "price" of a token as the amount equivalent to the other in the pool.

Chainlink Aggregators used in this example [(Goerli)](https://docs.chain.link/data-feeds/price-feeds/addresses#Goerli%20Testnet):
- BTC/USD
- ETH/USD
- LINK/USD

Uniswap Pools used in this example:
- [USDC/WETH (Goerli)](https://www.geckoterminal.com/pt/goerli-testnet/pools/0x647595535c370f6092c6dae9d05a7ce9a8819f37)
- [UNI/WETH (Goerli)](https://www.geckoterminal.com/pt/goerli-testnet/pools/0x28cee28a7c4b4022ac92685c07d2f33ab1a0e122)
- [ZETA/WETH (Goerli)](https://www.geckoterminal.com/pt/goerli-testnet/pools/0xb3a16c2b68bbb0111ebd27871a5934b949837d95)

**Note that the Uniswap Pools are for ERC20, so we have USDC (USD Coin) and WETH (Wrapped ETH) isntead of USD and ETH.**


## Requirements

Please refer to the [rollups-examples requirements](https://github.com/cartesi/rollups-examples/tree/main/README.md#requirements).

To interact with the DApp in testnet the following is also needed:
1. [Metamask Plugin](https://metamask.io/)

## Contracts



### Deploying Smart Contracts

The easiest way to deploy a smart contract is through the [Remix IDE](https://remix.ethereum.org), so the proceedings are:

1. Creat a `token-prices.sol` in the contracts directory of the Remix IDE worspace.
2. Copy the choosen smart contract code and paste it into the one created in the Remix IDE workspace.
3. Compile the contract (Ctrl + s).
4. Click on the Tab "Deploy & run transactions".
5. Select the environment/network you want to deploy.
    1. If you are running locally, make sure to run the `docker compose` command first to bring up the test environment.
6. Click on `deploy`.

## Building

To build the application, run the following command:

```shell
docker buildx bake -f docker-bake.hcl -f docker-bake.override.hcl --load
```

## Running

To start the application, execute the following command:

```shell
docker compose up
```

The application can afterwards be shut down with the following command:

```shell
docker compose down -v
```

### Deploying DApps

Deploying a new Cartesi DApp to a blockchain requires creating a smart contract on that network, as well as running a validator node for the DApp.

The first step is to build the DApp's back-end machine, which will produce a hash that serves as a unique identifier.

```shell
docker buildx bake -f docker-bake.hcl -f docker-bake.override.hcl machine --load
```

Once the machine docker image is ready, we can use it to deploy a corresponding Rollups smart contract.
This requires you to specify the account and RPC gateway to use when submitting the deploy transaction on the target network, which can be done by defining the following environment variables:

```shell
export MNEMONIC=<user sequence of twelve words>
export RPC_URL=<https://your.rpc.gateway>
```

For example, to deploy to the Goerli testnet using an Alchemy RPC node, you could execute:

```shell
export MNEMONIC=<user sequence of twelve words>
export RPC_URL=https://eth-goerli.alchemyapi.io/v2/<USER_KEY>
```

With that in place, you can submit a deploy transaction to the Cartesi DApp Factory contract on the target network by executing the following command:

```shell
DAPP_NAME="token-prices" docker compose --env-file env.<network> -f deploy-testnet.yml up
```

Here, `env.<network>` specifies general parameters for the target network, like its name and chain ID. In the case of Goerli, the command would be:

```shell
DAPP_NAME="token-prices" docker compose --env-file env.goerli -f deploy-testnet.yml up
```

This will create a file at `deployments/<network>/token-prices.json` with the deployed contract's address.
Once the command finishes, it is advisable to stop the docker compose and remove the volumes created when executing it.

```shell
DAPP_NAME="token-prices" docker compose --env-file env.<network> -f deploy-testnet.yml down -v
```

After that, a corresponding Cartesi Validator Node must also be instantiated in order to interact with the deployed smart contract on the target network and handle the back-end logic of the DApp.
Aside from the environment variables defined before, the node will also need a secure websocket endpoint for the RPC gateway (WSS URL).

For example, for Goerli and Alchemy, you would set the following additional variable:

```shell
export WSS_URL=wss://eth-goerli.alchemyapi.io/v2/<USER_KEY>
```

Then, the node itself can be started by running a docker compose as follows:

```shell
DAPP_NAME="token-prices" docker compose --env-file env.<network> -f docker-compose-testnet.yml -f docker-compose.override.yml up
```

Alternatively, you can also run the node on host mode by executing:

```shell
DAPP_NAME="token-prices" docker compose --env-file env.<network> -f docker-compose-testnet.yml -f docker-compose.override.yml -f docker-compose-host-testnet.yml up
```

## Running the back-end in host mode

When developing an application, it is often important to easily test and debug it. For that matter, it is possible to run the Cartesi Rollups environment in [host mode](https://github.com/cartesi/rollups-examples/tree/main/README.md#host-mode), so that the DApp's back-end can be executed directly on the host machine, allowing it to be debugged using regular development tools such as an IDE.

The host environment can be executed with the following command:

```shell
docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose-host.yml up
```

This DApp's back-end is written in Python, so to run it in your machine you need to have `python3` installed.

In order to start the back-end, run the following commands in a dedicated terminal:

```shell
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
ROLLUP_HTTP_SERVER_URL="http://127.0.0.1:5004" python3 token-prices.py
```

The final command will effectively run the back-end and send corresponding outputs to port `5004`.
It can optionally be configured in an IDE to allow interactive debugging using features like breakpoints.

You can also use a tool like [entr](https://eradman.com/entrproject/) to restart the back-end automatically when the code changes. For example:

```shell
ls *.py | ROLLUP_HTTP_SERVER_URL="http://127.0.0.1:5004" entr -r python3 token-prices.py
```

After the back-end successfully starts, it should print an output like the following:

```log
INFO:__main__:HTTP rollup_server url is http://127.0.0.1:5004
INFO:__main__:Sending finish
```

After that, you can interact with the application normally [as explained above](#interacting-with-the-application).


## Interacting with the DApp

After the `token-prices` contract was deployed and the Cartesi Node is running the application is ready and users can finally interact with it. The procedure for interacting is as follows:

1. On Remix IDE, execute the `set_dapp_address` method of the `token-prices` contract to set the rollup contract address. This step is to allow the layer-1 contract to send inputs to the Cartesi Rollups.
2. Execute the `pricesToRollups` (Chainlink or Uniswap) method to feed the prices to the Cartesi DApp.
3. Check the notice with the token prices produced by the Cartesi DApp using the [frontend-console](https://github.com/cartesi/rollups-examples/tree/main/frontend-console).