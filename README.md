# token-prices DApp

```
Cartesi Rollups version: 1.0.x
```

This DApp exemplifies two ways to feed token prices to a Cartesi Rollups DApp. The DApp receives the prices of the tokens as Input and generates a notice with the information received. Two contracts provide the prices in two ways, one using [Chainlink](https://docs.chain.link/) and the other using [Uniswap](https://uniswap.org/). Chainlink is a Decentralized Oracle Network (DON) that can feed the DApp with real-world prices, like the ETH price in dollars. It does that through Aggregators that observe and aggregate the price of some token. Uniswap, on the other hand, is a decentralized protocol for swapping ERC20 tokens, so it has pools of pairs of ERC20 tokens and provides the "price" of a token as pool's informations.

Chainlink Aggregators used in this example [(Sepolia)](https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum&page=1#Sepolia%20Testnet):
- BTC/USD
- ETH/USD
- LINK/USD

Uniswap Pools used in this example:
- [WBTC/DAI (Sepolia)](https://www.geckoterminal.com/sepolia-testnet/pools/0xd4c8fb61a56e55e898288177272bdb556ab36b2a)
- [UNI/WETH (Sepolia)](https://www.geckoterminal.com/sepolia-testnet/pools/0x287b0e934ed0439e2a7b1d5f0fc25ea2c24b64f7)
- [LINK/WETH (Sepolia)](https://www.geckoterminal.com/sepolia-testnet/pools/0xdd7cc9a0da070fb8b60dc6680b596133fb4a7100)

**Note that the Uniswap Pools are for ERC20 tokens, so we have WBTC (Wrapped Bitcoin) and WETH (Wrapped ETH) isntead of BTC and ETH.**

> [!IMPORTANT]
> This DApp is not to be executed locally since it integrates with other solutions (Chainlink and Uniswap).

## Requirements

Please refer to the [rollups-examples requirements](https://github.com/cartesi/rollups-examples/tree/main/README.md#requirements).

To interact with the DApp in testnet the following is also needed:
1. [Metamask Plugin](https://metamask.io/)

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
docker buildx bake -f docker-bake.hcl -f docker-bake.override.hcl machine --load --set *.args.NETWORK=sepolia
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

Here, `env.<network>` specifies general parameters for the target network, like its name and chain ID. In the case of Sepolia, the command would be:

```shell
DAPP_NAME="token-prices" docker compose --env-file env.sepolia -f deploy-testnet.yml up
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
DAPP_NAME="token-prices" docker compose --env-file env.<network> -f docker-compose-testnet.yml up
```

Alternatively, you can also run the node on host mode by executing:

```shell
DAPP_NAME="token-prices" docker compose --env-file env.<network> -f docker-compose-testnet.yml -f docker-compose-host-testnet.yml up
```

## Running the back-end in host mode

When developing an application, it is often important to easily test and debug it. For that matter, it is possible to run the Cartesi Rollups environment in [host mode](https://github.com/cartesi/rollups-examples/tree/main/README.md#host-mode), so that the DApp's back-end can be executed directly on the host machine, allowing it to be debugged using regular development tools such as an IDE.

The host environment can be executed with the following command:

```shell
docker compose -f docker-compose.yml -f docker-compose-host.yml up
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

Before beginning the interaction, declare the variables that we will be using. So first, go to a separate terminal window and execute the commands below to initialize the variables.

> [!IMPORTANT]
> Set the MNEMONIC and RPC_URL you will be using, then set the addresses for the contracts (retrieved from the `deployments` folder).

```shell
export MNEMONIC="..."
export RPC_URL="http://..."
export CHAINLINK_ADDRESS="0x..."
export UNISWAP_ADDRESS="0x..."
export DAPP_ADDRESS="0x..."
```

### Trough Chainlink
1. Set Cartesi Rollups DApp address
```shell
docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --mnemonic \"$MNEMONIC\" --rpc-url $RPC_URL $CHAINLINK_ADDRESS \"set_dapp_address(address)\" $DAPP_ADDRESS"
```

2. Send the prices informations
```shell
docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --mnemonic \"$MNEMONIC\" --rpc-url $RPC_URL $CHAINLINK_ADDRESS \"pricesToRollups()\""
```

### Trough Uniswap
1. Set Cartesi Rollups DApp address
```shell
docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --mnemonic \"$MNEMONIC\" --rpc-url $RPC_URL $UNISWAP_ADDRESS \"set_dapp_address(address)\" $DAPP_ADDRESS"
```

2. Send the pools informations
```shell
docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --mnemonic \"$MNEMONIC\" --rpc-url $RPC_URL $UNISWAP_ADDRESS \"pricesToRollups()\""
```