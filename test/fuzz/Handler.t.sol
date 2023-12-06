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
    address[] public usersWithCollateralDeposited;

    constructor(DSCEngine _dscEngine, DecentralisedStableCoin _dsc){
        dscEngine = _dscEngine;
        dsc = _dsc;
        address[] memory collateralTokens = dscEngine.getCollateralTokenAddresses();
        weth = collateralTokens[0];
        wbtc = collateralTokens[1];
    }

    function mintDsc(uint256 amount, uint256 addressSeed) public {
        if(usersWithCollateralDeposited.length == 0) return;
        address sender = usersWithCollateralDeposited[addressSeed%usersWithCollateralDeposited.length];
        amount = bound(amount,1,type(uint96).max);
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dscEngine.getAccountInformation(msg.sender);
        int256 maxDscToMint = (int256(collateralValueInUsd) /2) - int256(totalDscMinted);
        if(maxDscToMint < 0) return;
        amount = bound(amount,0,uint256(maxDscToMint));
        if(amount == 0) return;
        vm.startPrank(sender);
        dscEngine.mintDsc(amount);
        vm.stopPrank();
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
        usersWithCollateralDeposited.push(msg.sender);
    }

    function redeemCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
        address collateral = _getCollateralFromSeed(collateralSeed);
        uint256 maxCollateralBalance;
        if(collateral == weth){
            maxCollateralBalance = dscEngine.getFromCollateralDepositedMapping(msg.sender, weth);
        } else {
            maxCollateralBalance = dscEngine.getFromCollateralDepositedMapping(msg.sender, wbtc);
        }
        amountCollateral = bound(amountCollateral,0,maxCollateralBalance);
        if (amountCollateral == 0) { return; }
        dscEngine.redeemCollateral(collateral, amountCollateral);
    }

    //helper
    function _getCollateralFromSeed(uint256 collateralSeed) public view returns(address){
        if((collateralSeed % 2) == 0){
            return weth;
        }
        return wbtc;
    }
}