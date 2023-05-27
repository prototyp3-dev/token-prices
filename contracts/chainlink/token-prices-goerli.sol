// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@cartesi/rollups/contracts/interfaces/IInput.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TokenPricesChainlinkV3 {
    address deployer;
    address L2_DAPP;

    AggregatorV3Interface internal btcFeed;
    AggregatorV3Interface internal ethFeed;
    AggregatorV3Interface internal linkFeed;

    /**
        * Network: Goerli
        * Aggregator: TOKEN/USD
    */
    constructor() {
        btcFeed = AggregatorV3Interface(
            0xA39434A63A52E749F02807ae27335515BA4b07F7
        );

        ethFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );

        linkFeed = AggregatorV3Interface(
            0x48731cF7e84dc94C5f84577882c14Be11a5B7456
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
        IInput(L2_DAPP).addInput(payload);
    }
}