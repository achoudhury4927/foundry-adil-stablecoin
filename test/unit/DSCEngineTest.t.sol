// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DecentralisedStableCoin} from "../../src/DecentralisedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {MockERC20WETH} from "../mocks/MockERC20WETH.sol";
import {MockERC20WBTC} from "../mocks/MockERC20WBTC.sol";
import {Reject} from "../util/Reject.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralisedStableCoin dsc;
    DSCEngine dscEngine;
    HelperConfig helperConfig;
    Reject rejecter;
    address wethUsdPriceFeed;
    address wbtcUsdPriceFeed;
    address weth;
    address wbtc;

    address public USER = makeAddr("user");
    uint256 public constant TENETHER = 10 ether;

    function setUp() public {
        rejecter = new Reject();
        deployer = new DeployDSC();
        (dsc, dscEngine, helperConfig) = deployer.run();
        (wethUsdPriceFeed, wbtcUsdPriceFeed, weth, wbtc,) = helperConfig.activeNetworkConfig();
        MockERC20WETH(weth).mint(USER, TENETHER);
        MockERC20WETH(weth).mint(address(rejecter), TENETHER);
    }

    function test_GetUsdValue_OfEth() public {
        uint256 ethAmount = 15e18; //15 eth = 15,000,000,000,000,000,000 gwei
        uint256 expectedUsd = 30000e18; //15*2000 = 30,000. Base e18 for easy multiplication of eth in gwei format.
        uint256 actualUsd = dscEngine.getUsdValue(weth, ethAmount);
        assertEq(expectedUsd, actualUsd);
    }

    function test_GetUsdValue_OfBtc() public {
        uint256 btcAmount = 15e18; //15 wbtc = 15,000,000,000,000,000,000 gwei
        uint256 expectedUsd = 15000e18; //15*1000 = 15,000. Base e18 for easy multiplication of eth in gwei format.
        uint256 actualUsd = dscEngine.getUsdValue(wbtc, btcAmount);
        assertEq(expectedUsd, actualUsd);
    }

    function test_DepositCollateral_RevertIf_CollateralDepositedIsZero() public {
        vm.startPrank(USER);
        MockERC20WETH(weth).approve(address(dscEngine), TENETHER);
        vm.expectRevert(DSCEngine.DSCEngine_AmountNeedsToBeMoreThanZero.selector);
        dscEngine.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function test_DepositCollateral_RevertIf_TokenCollateralIsNotAllowed() public {
        MockERC20WETH unapprovedWethImplmentation = new MockERC20WETH();
        vm.expectRevert(DSCEngine.DSCEngine_NotAllowedToken.selector);
        dscEngine.depositCollateral(address(unapprovedWethImplmentation), TENETHER);
    }

    function test_DepositCollateral_RevertIf_TransferFailed() public {
        //Figure out how to trigger the following error
        //vm.expectRevert(DSCEngine.DSCEngine_TransferFailed.selector);
        //dscEngine.depositCollateral(weth, TENETHER);
    }

    function test_DepositCollateral_CollateralDespoitedMappingIsUpated() public {
        vm.startPrank(USER);
        MockERC20WETH(weth).approve(address(dscEngine), TENETHER);
        dscEngine.depositCollateral(weth, TENETHER);
        assertEq(TENETHER, dscEngine.getFromCollateralDepositedMapping(USER, weth));
    }

    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    function test_DepositCollateral_EmitsCollateralDeposited() public {
        vm.startPrank(USER);
        MockERC20WETH(weth).approve(address(dscEngine), TENETHER);
        vm.expectEmit(true, true, true, true);
        emit CollateralDeposited(USER, weth, TENETHER);
        dscEngine.depositCollateral(weth, TENETHER);
    }

    function test_DepositCollateral_TransfersCollateralToDSCEngine() public {
        vm.startPrank(USER);
        MockERC20WETH(weth).approve(address(dscEngine), TENETHER);
        dscEngine.depositCollateral(weth, TENETHER);
        assertEq(TENETHER, MockERC20WETH(weth).balanceOf(address(dscEngine)));
    }
}
