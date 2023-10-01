// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@cartesi/rollups/contracts/inputs/IInputBox.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TokenPricesChainlinkV3 {
    address deployer;
    address L2_DAPP;
    IInputBox inputBox = IInputBox(0x59b22D57D4f067708AB0c00552767405926dc768);

    AggregatorV3Interface internal btcFeed;
    AggregatorV3Interface internal ethFeed;
    AggregatorV3Interface internal linkFeed;

    /**
        * Network: Sepolia
        * Aggregator: TOKEN/USD
    */
    constructor() {
        btcFeed = AggregatorV3Interface(
            0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
        );

        ethFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );

        linkFeed = AggregatorV3Interface(
            0xc59E3633BAAC79493d908e63626716e204A45EdF
        );

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
        ) = btcFeed.latestRoundData();

        // get ETH/USD latest price
        (
            /* uint80 roundID */,
            int ethPrice,
            /*uint startedAt*/,
            uint ethTtimeStamp,
            /*uint80 answeredInRound*/
        ) = ethFeed.latestRoundData();

        // get LINK/USD latest price
        (
            /* uint80 roundID */,
            int linkPrice,
            /*uint startedAt*/,
            uint linkTtimeStamp,
            /*uint80 answeredInRound*/
        ) = linkFeed.latestRoundData();

        bytes memory payload = abi.encode(
            btcTtimeStamp, btcPrice,
            ethTtimeStamp, ethPrice,
            linkTtimeStamp, linkPrice
        );

        // calls Cartesi's addInput to send the token prices info to L2
        inputBox.addInput(L2_DAPP, payload);
    }
}