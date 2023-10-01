// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "@cartesi/rollups/contracts/inputs/IInputBox.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";

contract TokenPricesUniswapV3 {
    address deployer;
    address L2_DAPP;
    IInputBox inputBox = IInputBox(0x59b22D57D4f067708AB0c00552767405926dc768);

    // secondsAgo: From how long ago each cumulative tick and liquidity value should be returned
    uint32[] secondsAgo = [3600, 0];

    // https://www.geckoterminal.com/sepolia-testnet/pools/0xd4c8fb61a56e55e898288177272bdb556ab36b2a
    IUniswapV3Pool internal wbtc_dai_pool = IUniswapV3Pool(0xD4C8Fb61A56E55e898288177272bDb556Ab36b2A);

    // https://www.geckoterminal.com/sepolia-testnet/pools/0x287b0e934ed0439e2a7b1d5f0fc25ea2c24b64f7
    IUniswapV3Pool internal uni_weth_pool = IUniswapV3Pool(0x287B0e934ed0439E2a7b1d5F0FC25eA2c24b64f7);

    // https://www.geckoterminal.com/sepolia-testnet/pools/0xdd7cc9a0da070fb8b60dc6680b596133fb4a7100
    IUniswapV3Pool internal link_weth_pool = IUniswapV3Pool(0xDD7CC9a0dA070fB8B60dC6680b596133fb4A7100);

    // From Uniswap docs:
    // In an ideal world, the quoter functions would be view functions, which would make them very easy to query on-chain with minimal gas costs.
    // However, the Uniswap V3 Quoter contracts rely on state-changing calls designed to be reverted to return the desired data.
    // This means calling the quoter will be very expensive and should not be called on-chain.
    IQuoter quoter = IQuoter(0xA5e7615F9c984EAc435f1A4EeeAee8B6Ca984Eac);


    constructor() {
        deployer = msg.sender;
    }

    function set_dapp_address(address l2_dapp) public {
        require(msg.sender == deployer);

        L2_DAPP = l2_dapp;
    }

    function _process_prices(IUniswapV3Pool pool) internal returns(uint256, int56[] memory, uint160[] memory) {
        // secondsAgo: From how long ago each cumulative tick and liquidity value should be returned
        // tickCumulatives: Cumulative tick values as of each secondsAgos from the current block timestamp
        // secondsPerLiquidityCumulativeX128s: Cumulative seconds per liquidity-in-range value as of each secondsAgos from the current block
        (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s) = pool.observe(secondsAgo);
        uint256 price = quoter.quoteExactInputSingle(pool.token0(), pool.token1(), pool.fee(), 1, 0);

        return (price, tickCumulatives, secondsPerLiquidityCumulativeX128s);
    }

    function pricesToRollups() public {
        require(L2_DAPP != address(0));

        // 1 wbtc equals to ? dai
        (uint256 wbtc_dai, int56[] memory tickCumulativesWbtcDai, uint160[] memory secondsPerLiquidityCumulativeX128sWbtcDai) = _process_prices(wbtc_dai_pool);

        // 1 uni equals to ? weth
        (uint256 uni_weth, int56[] memory tickCumulativesUniWETH, uint160[] memory secondsPerLiquidityCumulativeX128sUniWETH) = _process_prices(uni_weth_pool);

        // 1 link equals to ? weth
        (uint256 link_weth, int56[] memory tickCumulativesLinkWETH, uint160[] memory secondsPerLiquidityCumulativeX128sLinkWETH) = _process_prices(link_weth_pool);

        bytes memory payload = abi.encode(
            wbtc_dai, tickCumulativesWbtcDai, secondsPerLiquidityCumulativeX128sWbtcDai,
            uni_weth, tickCumulativesUniWETH, secondsPerLiquidityCumulativeX128sUniWETH,
            link_weth, tickCumulativesLinkWETH, secondsPerLiquidityCumulativeX128sLinkWETH
        );

        // calls Cartesi's addInput to send the token prices info to L2
        inputBox.addInput(L2_DAPP, payload);
    }
}