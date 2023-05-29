// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@cartesi/rollups@0.9.0/contracts/inputs/IInputBox.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TokenPricesChainlinkV3 {
    address deployer;
    address L2_DAPP;


    // https://github.com/cartesi/rollups/blob/main/onchain/rollups/deployments/sepolia/InputBox.json
    IInputBox internal cartesiInputBox = IInputBox(
        0x5a723220579C0DCb8C9253E6b4c62e572E379945 // Cartesi inputBox Sepolia addr
    );

    // https://docs.chain.link/data-feeds/price-feeds/addresses#Sepolia%20Testnet
    AggregatorV3Interface internal btcUsdFeed = AggregatorV3Interface(
        0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43 // BTC/USD Feed Sepolia addr
    );
    AggregatorV3Interface internal ethUsdFeed = AggregatorV3Interface(
        0x694AA1769357215DE4FAC081bf1f309aDC325306 // ETH/USD Feed Sepolia addr
    );
    AggregatorV3Interface internal linkUsdFeed = AggregatorV3Interface(
        0xc59E3633BAAC79493d908e63626716e204A45EdF // LINK/USD Feed Sepolia addr
    );

    constructor() {
        deployer = msg.sender;
    }

    function set_dapp_address(address l2_dapp) public {
        require(msg.sender == deployer);

        L2_DAPP = l2_dapp;
    }

    function pricesToRollups() public {
        require(L2_DAPP != address(0));

        // get BTC/USD latest price
        (
            /* uint80 roundID */,
            int btcPrice,
            /*uint startedAt*/,
            uint btcTtimeStamp,
            /*uint80 answeredInRound*/
        ) = btcUsdFeed.latestRoundData();

        // get ETH/USD latest price
        (
            /* uint80 roundID */,
            int ethPrice,
            /*uint startedAt*/,
            uint ethTtimeStamp,
            /*uint80 answeredInRound*/
        ) = ethUsdFeed.latestRoundData();

        // get LINK/USD latest price
        (
            /* uint80 roundID */,
            int linkPrice,
            /*uint startedAt*/,
            uint linkTtimeStamp,
            /*uint80 answeredInRound*/
        ) = linkUsdFeed.latestRoundData();

        bytes memory payload = abi.encode(
            btcTtimeStamp, btcPrice,
            ethTtimeStamp, ethPrice,
            linkTtimeStamp, linkPrice
        );

        // calls Cartesi's addInput to send the token prices info to L2
        cartesiInputBox.addInput(L2_DAPP, payload);
    }
}