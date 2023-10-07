// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {DecentralisedStableCoin} from "../src/DecentralisedStableCoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";

/**
 * @title DeployDecentralisedStableCoin
 * @author Adil Choudhury
 *
 * This contract will deploy ASC token contract DecentralisedStableCoin
 */
contract DeployDSC is Script {
    HelperConfig helperConfig = new HelperConfig();

    function run() public returns (DecentralisedStableCoin, DSCEngine) {
        vm.startBroadcast();
        DecentralisedStableCoin dsc = new DecentralisedStableCoin();
        (address[] memory tokenAddress, address[] memory priceFeeds) = destructureSeploiaNetworkConfig();
        DSCEngine dscEngine = new DSCEngine(tokenAddress, priceFeeds,address(dsc));
        vm.stopBroadcast();
        return (dsc, dscEngine);
    }

    function destructureSeploiaNetworkConfig()
        public
        returns (address[] memory tokenAddress, address[] memory priceFeeds)
    {
        tokenAddress[0] = helperConfig.getSepoliaNetworkConfig().wbtc;
        tokenAddress[1] = helperConfig.getSepoliaNetworkConfig().weth;
        priceFeeds[0] = helperConfig.getSepoliaNetworkConfig().wbtcUsdPriceFeed;
        priceFeeds[1] = helperConfig.getSepoliaNetworkConfig().wethUsdPriceFeed;
    }
}
