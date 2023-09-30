// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {Script} from "forge-std/Script.sol";
import {DecentralisedStableCoin} from "../src/DecentralisedStableCoin.sol";

/**
 * @title DeployDecentralisedStableCoin
 * @author Adil Choudhury
 *
 * This contract will deploy ASC token contract DecentralisedStableCoin
 */
contract DeployDecentralisedStableCoin is Script {
    function run() public returns (DecentralisedStableCoin) {
        vm.startBroadcast();
        DecentralisedStableCoin ascContract = new DecentralisedStableCoin();
        vm.stopBroadcast();
        return ascContract;
    }
}
