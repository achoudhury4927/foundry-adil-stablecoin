// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DecentralisedStableCoin} from "../../src/DecentralisedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";
import {MockERC20WETH} from "../mocks/MockERC20WETH.sol";
import {MockERC20WBTC} from "../mocks/MockERC20WBTC.sol";

contract Handler is Test{
    DeployDSC deployer;
    DecentralisedStableCoin dsc;
    DSCEngine dscEngine;
    HelperConfig helperConfig;
    address wethUsdPriceFeed;
    address wbtcUsdPriceFeed;
    address weth;
    address wbtc;

    constructor(DSCEngine _dscEngine, DecentralisedStableCoin _dsc){
        dscEngine = _dscEngine;
        dsc = _dsc;
    }

    function depositCollateral(address collateralSeed, uint256 amountCollateral) public {
        dscEngine.depositCollateral(collateralSeed,amountCollateral);
    }
}