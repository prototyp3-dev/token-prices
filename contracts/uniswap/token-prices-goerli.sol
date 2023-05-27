// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "@cartesi/rollups/contracts/interfaces/IInput.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract TokenPricesUniswapV2 {
    address deployer;
    address L2_DAPP;

    // https://www.geckoterminal.com/pt/goerli-testnet/pools/0x647595535c370f6092c6dae9d05a7ce9a8819f37
    IUniswapV2Pair internal usdc_weth_pool = IUniswapV2Pair(0x647595535c370F6092C6daE9D05a7Ce9A8819F37);

    // https://www.geckoterminal.com/pt/goerli-testnet/pools/0x28cee28a7c4b4022ac92685c07d2f33ab1a0e122
    IUniswapV2Pair internal uni_weth_pool = IUniswapV2Pair(0x28cee28a7C4b4022AC92685C07d2f33Ab1A0e122);

    // https://www.geckoterminal.com/pt/goerli-testnet/pools/0xb3a16c2b68bbb0111ebd27871a5934b949837d95
    IUniswapV2Pair internal zeta_weth_pool = IUniswapV2Pair(0xb3A16C2B68BBB0111EbD27871a5934b949837D95);

    // https://docs.uniswap.org/contracts/v2/reference/smart-contracts/router-02
    IUniswapV2Router02 internal uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);


    constructor() {
        deployer = msg.sender;
    }

    function set_dapp_address(address l2_dapp) public {
        require(msg.sender == deployer);

        L2_DAPP = l2_dapp;
    }

    function pricesToRollups() public {
        require(L2_DAPP != address(0));

        (uint112 usdc_reserves, uint112 weth0_reserves, uint32 usdc_weth_ts) = usdc_weth_pool.getReserves();
        // 1 usdc equals to ? weth
        uint usdc_weth = uniswapV2Router.quote(1, usdc_reserves, weth0_reserves);

        (uint112 uni_reserves, uint112 weth1_reserves, uint32 uni_weth_ts) = uni_weth_pool.getReserves();
        // 1 uni equals to ? weth
        uint uni_weth = uniswapV2Router.quote(1, uni_reserves, weth1_reserves);

        (uint112 zeta_reserves, uint112 weth2_reserves, uint32 zeta_weth_ts) = zeta_weth_pool.getReserves();
        // 1 zeta equals to ? weth
        uint zeta_weth = uniswapV2Router.quote(1, zeta_reserves, weth2_reserves);

        bytes memory payload = abi.encode(
            usdc_weth, usdc_weth_ts, usdc_reserves, weth0_reserves,
            uni_weth, uni_weth_ts, uni_reserves, weth1_reserves,
            zeta_weth, zeta_weth_ts, zeta_reserves, weth2_reserves
        );

        // calls Cartesi's addInput to send the token prices info to L2
        IInput(L2_DAPP).addInput(payload);
    }
}