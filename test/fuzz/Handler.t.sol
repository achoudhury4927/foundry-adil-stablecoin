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
        address[] memory collateralTokens = dscEngine.getCollateralTokenAddresses();
        weth = collateralTokens[0];
        wbtc = collateralTokens[1];
    }

    function depositCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
        address collateral = _getCollateralFromSeed(collateralSeed);
        amountCollateral = bound(amountCollateral, 1, type(uint96).max); //If it were uint256 max then any further deposits would revert

        vm.startPrank(msg.sender);
        if(collateral == weth){
            MockERC20WETH(collateral).mint(msg.sender, amountCollateral);
            MockERC20WETH(collateral).approve(address(dscEngine), amountCollateral);
        } else {
            MockERC20WBTC(collateral).mint(msg.sender, amountCollateral);
            MockERC20WBTC(collateral).approve(address(dscEngine), amountCollateral);
        }
        dscEngine.depositCollateral(collateral,amountCollateral);
        vm.stopPrank();
    }

    //helper
    function _getCollateralFromSeed(uint256 collateralSeed) public view returns(address){
        if((collateralSeed % 2) == 0){
            return weth;
        }
        return wbtc;
    }
}