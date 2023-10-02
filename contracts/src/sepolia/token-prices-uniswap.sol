// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "@cartesi/rollups/contracts/inputs/IInputBox.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

contract TokenPricesUniswapV3 {
    address deployer;
    address public L2_DAPP;
    IInputBox inputBox = IInputBox(0x59b22D57D4f067708AB0c00552767405926dc768);
    
    // https://www.geckoterminal.com/sepolia-testnet/pools/0xd4c8fb61a56e55e898288177272bdb556ab36b2a
    IUniswapV3Pool internal wbtc_dai_pool = IUniswapV3Pool(0xD4C8Fb61A56E55e898288177272bDb556Ab36b2A);

    // https://www.geckoterminal.com/sepolia-testnet/pools/0x287b0e934ed0439e2a7b1d5f0fc25ea2c24b64f7
    IUniswapV3Pool internal uni_weth_pool = IUniswapV3Pool(0x287B0e934ed0439E2a7b1d5F0FC25eA2c24b64f7);

    // https://www.geckoterminal.com/sepolia-testnet/pools/0xdd7cc9a0da070fb8b60dc6680b596133fb4a7100
    IUniswapV3Pool internal link_weth_pool = IUniswapV3Pool(0xDD7CC9a0dA070fB8B60dC6680b596133fb4A7100);

    // secondsAgo: From how long ago each cumulative tick and liquidity value should be returned
    uint32[] secondsAgo = [3600, 0];

    int56[] tickCumulativesWBTCDai;
    uint160[] secondsPerLiquidityCumulativeX128sWBTCDai;
    
    int56[] tickCumulativesUniWETH;
    uint160[] secondsPerLiquidityCumulativeX128sUniWETH;
    
    int56[] tickCumulativesLinkWETH;
    uint160[] secondsPerLiquidityCumulativeX128sLinkWETH;


    constructor() {
        deployer = msg.sender;
    }

    function set_dapp_address(address l2_dapp) public {
        require(msg.sender == deployer);

        L2_DAPP = l2_dapp;
    }


    function pricesToRollups() public {
        require(L2_DAPP != address(0));

        // 1 wbtc equals to ? dai
        (tickCumulativesWBTCDai, secondsPerLiquidityCumulativeX128sWBTCDai) = wbtc_dai_pool.observe(secondsAgo);

        // 1 uni equals to ? weth
        (tickCumulativesUniWETH, secondsPerLiquidityCumulativeX128sUniWETH) = uni_weth_pool.observe(secondsAgo);

        // 1 link equals to ? weth
        (tickCumulativesLinkWETH, secondsPerLiquidityCumulativeX128sLinkWETH) = link_weth_pool.observe(secondsAgo);
        
        bytes memory payload = abi.encode(
            tickCumulativesWBTCDai, secondsPerLiquidityCumulativeX128sWBTCDai,
            tickCumulativesUniWETH, secondsPerLiquidityCumulativeX128sUniWETH,
            tickCumulativesLinkWETH, secondsPerLiquidityCumulativeX128sLinkWETH
        );

        // calls Cartesi's addInput to send the token prices info to L2
        inputBox.addInput(L2_DAPP, payload);
    }
}