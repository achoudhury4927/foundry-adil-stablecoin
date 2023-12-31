// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DecentralisedStableCoin} from "../../src/DecentralisedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";
import {MockERC20WETH} from "../mocks/MockERC20WETH.sol";
import {MockERC20WBTC} from "../mocks/MockERC20WBTC.sol";
import {Reject} from "../util/Reject.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralisedStableCoin dsc;
    DSCEngine dscEngine;
    HelperConfig helperConfig;
    address wethUsdPriceFeed;
    address wbtcUsdPriceFeed;
    address weth;
    address wbtc;

    address public USER = makeAddr("user");
    address public LIQUIDATOR = makeAddr("liquidator");
    uint256 public constant TENETHER = 10 ether;
    uint256 public constant FIVEBITCOIN = 5 ether;
    uint256 public constant ONETHOUSANDDSC = 1 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dscEngine, helperConfig) = deployer.run();
        (wethUsdPriceFeed, wbtcUsdPriceFeed, weth, wbtc,) = helperConfig.activeNetworkConfig();
        MockERC20WETH(weth).mint(USER, TENETHER);
        MockERC20WBTC(wbtc).mint(USER, FIVEBITCOIN);
        MockERC20WETH(weth).mint(LIQUIDATOR, 10000 ether);
        MockERC20WBTC(wbtc).mint(LIQUIDATOR, FIVEBITCOIN);
    }

    address[] tokenAddress;
    address[] priceFeedAddress;

    //--------------Constructor Tests--------------//

    function test_Constructor_RevertsIf_LengthOfPricefeedsAndTokensNotSame() public {
        tokenAddress = [weth, wbtc];
        priceFeedAddress = [wethUsdPriceFeed];
        DSCEngine revertEngine;
        vm.expectRevert(DSCEngine.DSCEngine_TokenAddressesAndPriceFeedAddressesMustBeTheSameLength.selector);
        revertEngine = new DSCEngine(tokenAddress,priceFeedAddress,address(dsc));
    }

    function test_Constructor_UpdatesPricefeedsMapping() public {
        assertEq(dscEngine.getFromPricefeedsMapping(weth), wethUsdPriceFeed);
        assertEq(dscEngine.getFromPricefeedsMapping(wbtc), wbtcUsdPriceFeed);
    }

    function test_Constructor_UpdatesCollateralTokensArray() public {
        assertEq(dscEngine.getFromCollateralTokensArray(0), weth);
        assertEq(dscEngine.getFromCollateralTokensArray(1), wbtc);
    }

    function test_Constructor_UpdatesDscAddressCorrectly() public {
        assertEq(dscEngine.getDscAddress(), address(dsc));
    }

    //Modifier to approve weth for the user, this function does not stop prank
    modifier approveWeth() {
        vm.startPrank(USER);
        MockERC20WETH(weth).approve(address(dscEngine), TENETHER);
        _;
    }

    //--------------DepositCollateralAndMintDsc Tests--------------//

    function test_DepositCollateralAndMintDsc_TransfersCollateralToDSCEngine() public approveWeth {
        dscEngine.depositCollateralAndMintDsc(weth, TENETHER, ONETHOUSANDDSC);
        assertEq(TENETHER, dscEngine.getFromCollateralDepositedMapping(USER, weth));
        assertEq(ONETHOUSANDDSC, dscEngine.getFromDSCMintedMapping(USER));
        assertEq(dsc.balanceOf(USER), ONETHOUSANDDSC);
        vm.stopPrank();
    }

    //--------------DepositCollateral Tests--------------//

    function test_DepositCollateral_RevertIf_CollateralDepositedIsZero() public approveWeth {
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
        //dscEngine.depositCollateral(weth, TENETHER)
    }

    function test_DepositCollateral_CollateralDespoitedMappingIsUpated() public approveWeth{
        dscEngine.depositCollateral(weth, TENETHER);
        assertEq(TENETHER, dscEngine.getFromCollateralDepositedMapping(USER, weth));
        vm.stopPrank();
    }

    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    function test_DepositCollateral_EmitsCollateralDeposited() public approveWeth {
        vm.expectEmit(true, true, true, true);
        emit CollateralDeposited(USER, weth, TENETHER);
        dscEngine.depositCollateral(weth, TENETHER);
        vm.stopPrank();
    }

    function test_DepositCollateral_TransfersCollateralToDSCEngine() public approveWeth {
        dscEngine.depositCollateral(weth, TENETHER);
        assertEq(TENETHER, MockERC20WETH(weth).balanceOf(address(dscEngine)));
        vm.stopPrank();
    }
    //--------------MintDsc Tests--------------//

    function test_MintDsc_UpdatesDscMintedMapping() public approveWeth {
        dscEngine.depositCollateral(weth, TENETHER);
        dscEngine.mintDsc(ONETHOUSANDDSC);
        assertEq(ONETHOUSANDDSC, dscEngine.getFromDSCMintedMapping(USER));
        vm.stopPrank();
    }

    function test_MintDsc_RevertsIf_HealthFactorIsBroken() public approveWeth {
        dscEngine.depositCollateral(weth, 1 ether);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine_BreaksHealthFactor.selector, 1000));
        dscEngine.mintDsc(ONETHOUSANDDSC * 1 ether);
        vm.stopPrank();
    }

    //--------------RedeemCollateralForDsc Tests--------------//

    function test_RedeemCollateralForDsc_TransfersCollateralToUser() public approveWeth {
        dsc.approve(address(dscEngine), TENETHER * 2);
        dscEngine.depositCollateralAndMintDsc(weth, TENETHER, ONETHOUSANDDSC);
        dscEngine.redeemCollateralForDsc(weth, (TENETHER / 2), (ONETHOUSANDDSC / 2));
        assertEq(TENETHER / 2, dscEngine.getFromCollateralDepositedMapping(USER, weth));
        assertEq(TENETHER / 2, MockERC20WETH(weth).balanceOf(USER));
        assertEq((ONETHOUSANDDSC / 2), dscEngine.getFromDSCMintedMapping(USER));
        vm.stopPrank();
    }

    //--------------RedeemCollateral Tests--------------//

    function test_RedeemCollateral_RevertsIfAmountIsZero() public {
        vm.expectRevert(DSCEngine.DSCEngine_AmountNeedsToBeMoreThanZero.selector);
        dscEngine.redeemCollateral(weth, 0);
    }

    function test_RedeemCollateral_RevertsIfHealthFactorIsBroken() public approveWeth {
        dsc.approve(address(dscEngine), TENETHER);
        dscEngine.depositCollateralAndMintDsc(weth, TENETHER, ONETHOUSANDDSC);
        assertEq(TENETHER, dscEngine.getFromCollateralDepositedMapping(USER, weth));
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine_BreaksHealthFactor.selector, 0));
        dscEngine.redeemCollateral(weth, TENETHER);
        vm.stopPrank();
    }

    function test_RedeemCollateral_UpdatesCollateralDepositedMapping() public approveWeth {
        dsc.approve(address(dscEngine), TENETHER);
        dscEngine.depositCollateralAndMintDsc(weth, TENETHER, ONETHOUSANDDSC);
        assertEq(TENETHER, dscEngine.getFromCollateralDepositedMapping(USER, weth));
        dscEngine.redeemCollateral(weth, (TENETHER / 2));
        assertEq(TENETHER / 2, dscEngine.getFromCollateralDepositedMapping(USER, weth));
        vm.stopPrank();
    }

    event CollatedRedeemed(
        address indexed redeemedFrom, address indexed redeemedTo, address indexed token, uint256 amount
    );

    function test_RedeemCollateral_EmitsCollateralRedeemed() public approveWeth {
        dsc.approve(address(dscEngine), TENETHER * 2);
        dscEngine.depositCollateralAndMintDsc(weth, TENETHER, ONETHOUSANDDSC);
        vm.expectEmit(true, true, true, true);
        emit CollatedRedeemed(USER, USER, weth, TENETHER / 2);
        dscEngine.redeemCollateral(weth, (TENETHER / 2));
        vm.stopPrank();
    }

    //--------------BurnDsc Tests--------------//

    function test_BurnDsc_RevertsIfAmountIsZero() public {
        vm.expectRevert(DSCEngine.DSCEngine_AmountNeedsToBeMoreThanZero.selector);
        dscEngine.burnDsc(0);
    }

    function test_BurnDsc_UpdatesDSCMintedMapping() public approveWeth {
        dsc.approve(address(dscEngine), TENETHER);
        dscEngine.depositCollateralAndMintDsc(weth, TENETHER, ONETHOUSANDDSC);
        assertEq(ONETHOUSANDDSC, dscEngine.getFromDSCMintedMapping(USER));
        dscEngine.burnDsc(ONETHOUSANDDSC);
        assertEq(0, dscEngine.getFromDSCMintedMapping(USER));
        vm.stopPrank();
    }

    function test_BurnDsc_ReducesDSCBalanceCorrectly() public approveWeth {
        dsc.approve(address(dscEngine), TENETHER);
        dscEngine.depositCollateralAndMintDsc(weth, TENETHER, ONETHOUSANDDSC);
        assertEq(ONETHOUSANDDSC, dsc.balanceOf(USER));
        dscEngine.burnDsc(ONETHOUSANDDSC);
        assertEq(0, dsc.balanceOf(USER));
        vm.stopPrank();
    }

    function test_BurnDsc_RevertsIfHealthFactorIsBroken() public {
        //Can healthfactor be broken if dsc is burned?
        //Wouldnt healthfactor only be improved by burning DSC?
    }

    //--------------Liquidate Tests--------------//

    /** Modifier to setup for liquidation tests by:
     *   1. Approving balance for dscEngine to move weth for the user and liquidator
     *   2. Approving dsc balance for dscEngine to move dsc for the user and liquidator
     *   3. depositing collateral and minting dsc for the user and liquidator
     */
    modifier liquidationSetup() {
        vm.startPrank(USER);
        MockERC20WETH(weth).approve(address(dscEngine), TENETHER);
        dsc.approve(address(dscEngine), TENETHER);
        dscEngine.depositCollateralAndMintDsc(weth, 1 ether, 1000 ether);
        vm.stopPrank();
        vm.startPrank(LIQUIDATOR);
        MockERC20WETH(weth).approve(address(dscEngine), 1000 ether);
        dsc.approve(address(dscEngine), 1000 ether);
        dscEngine.depositCollateralAndMintDsc(weth, 1000 ether, 1000 ether);
        vm.stopPrank();
        _;
    }

    function test_Liquidate_RevertsIf_DebtToCoverIsZero() public {
        vm.startPrank(LIQUIDATOR);
        vm.expectRevert(DSCEngine.DSCEngine_AmountNeedsToBeMoreThanZero.selector);
        dscEngine.liquidate(weth, USER, 0);
        vm.stopPrank();
    }

    function test_Liquidate_RevertsIf_UserHealthFactorIsOkay() public approveWeth {
        dsc.approve(address(dscEngine), TENETHER);
        dscEngine.depositCollateralAndMintDsc(weth, TENETHER, ONETHOUSANDDSC);
        vm.stopPrank();
        vm.prank(LIQUIDATOR);
        vm.expectRevert(DSCEngine.DSCEngine_HealthFactorOkay.selector);
        dscEngine.liquidate(weth, USER, ONETHOUSANDDSC);
    }

    function test_Liquidate_RevertsIf_LiquidatingNonUser() public {
        vm.prank(LIQUIDATOR);
        vm.expectRevert(DSCEngine.DSCEngine_HealthFactorOkay.selector);
        dscEngine.liquidate(weth, USER, ONETHOUSANDDSC);
    }

    function test_Liquidate_ReducesCollateralDepositBalanceOfLiquidatee() public liquidationSetup {
        uint256 startingUserCollateralDepositedUsdBalance = dscEngine.getAccountCollateralValue(USER);
        assertEq(startingUserCollateralDepositedUsdBalance,2000 ether); // At this point 1 weth = $2000 so collateral value will be 2000e18 in as usd is retrieved in wei
        //update prices
        MockV3Aggregator(wethUsdPriceFeed).updateAnswer(20e8);
        vm.warp(3);
        //Verify collateral value reduced
        uint256 updatedUserCollateralDepositedUsdBalance = dscEngine.getAccountCollateralValue(USER);
        assertLt(updatedUserCollateralDepositedUsdBalance,startingUserCollateralDepositedUsdBalance);
        //liquidate user
        vm.prank(LIQUIDATOR);
        dscEngine.liquidate(weth, USER, 1000 ether);
        //verify user balances
        uint256 endingUserCollateralDepositedUsdBalance = dscEngine.getAccountCollateralValue(USER);
        assertEq(endingUserCollateralDepositedUsdBalance, 0);
    }

    function test_Liquidate_ImprovesHealthFactorOfLiquidatee() public liquidationSetup {
        vm.prank(USER);
        uint256 startingUserHealthFactor = dscEngine.getHealthFactor(USER);
        assertEq(startingUserHealthFactor,1 ether);
        //update prices
        MockV3Aggregator(wethUsdPriceFeed).updateAnswer(20e8);
        vm.warp(3);
        //liquidate user
        vm.prank(LIQUIDATOR);
        dscEngine.liquidate(weth, USER, 1000 ether);
        //verify user balances
        vm.prank(USER);
        uint256 endingUserHealthFactor = dscEngine.getHealthFactor(USER);
        assertEq(endingUserHealthFactor,type(uint256).max);
    }

    function test_Liquidate_PaysOffLiquidateeDebt() public liquidationSetup {
        uint256 startingUserDSCMintedMapping = dscEngine.getFromDSCMintedMapping(USER);
        assertEq(startingUserDSCMintedMapping, 1000 ether);
        //update prices
        MockV3Aggregator(wethUsdPriceFeed).updateAnswer(20e8);
        vm.warp(3);
        //liquidate user
        vm.prank(LIQUIDATOR);
        dscEngine.liquidate(weth, USER, 1000 ether);
        //verify user balances
        uint256 endingUserDSCMintedMapping = dscEngine.getFromDSCMintedMapping(USER);
        assertLt(endingUserDSCMintedMapping,startingUserDSCMintedMapping);
        assertEq(endingUserDSCMintedMapping, 0);
    }

    /*
     * The liquidator is redeeming the liquidatees collateral so their own should not reduce
     * The DSCEngine does not reduce the dscMinted balance of the liquidator so health factor doesnt change AFTER PRICE UPDATE
     * The DSCEngine does not reduce the dscMinted balance of the liquidator as they are paying of the liquidatees debt not their own
     */
     //TODO
    function test_Liquidate_DoesNotReduceLiquidatorCollateralBalance() public liquidationSetup {
        uint256 startingLiquidatorCollateralBalance = dscEngine.getFromCollateralDepositedMapping(LIQUIDATOR, weth);
        assertEq(startingLiquidatorCollateralBalance,1000 ether);

        MockV3Aggregator(wethUsdPriceFeed).updateAnswer(20e8);
        vm.warp(3);

        vm.prank(LIQUIDATOR);
        dscEngine.liquidate(weth, USER, 1000 ether);

        uint256 endingLiquidatorCollateralBalance = dscEngine.getFromCollateralDepositedMapping(LIQUIDATOR, weth);
        assertEq(endingLiquidatorCollateralBalance,startingLiquidatorCollateralBalance);
    }

    function test_Liquidate_DoesNotReduceLiquidatorDscMinted() public liquidationSetup {
        uint256 startingLiquidatorDSCMintedMapping = dscEngine.getFromDSCMintedMapping(LIQUIDATOR);
        assertEq(startingLiquidatorDSCMintedMapping, 1000 ether);

        MockV3Aggregator(wethUsdPriceFeed).updateAnswer(20e8);
        vm.warp(3);

        vm.prank(LIQUIDATOR);
        dscEngine.liquidate(weth, USER, 1000 ether);

        uint256 endingLiquidatorDSCMintedMapping = dscEngine.getFromDSCMintedMapping(LIQUIDATOR);
        assertEq(endingLiquidatorDSCMintedMapping,startingLiquidatorDSCMintedMapping);
    }

    function test_Liquidate_DoesNotChangeLiquidatorHealthFactor() public liquidationSetup {
        MockV3Aggregator(wethUsdPriceFeed).updateAnswer(20e8);
        vm.warp(3);

        //The healthfactor after the price update is what expect to remain unchanged during liquidation
        uint256 startingLiquidatorHealthFactor = dscEngine.getHealthFactor(LIQUIDATOR);

        vm.prank(LIQUIDATOR);
        dscEngine.liquidate(weth, USER, 1000 ether);

        uint256 endingLiquidatorHealthFactor = dscEngine.getHealthFactor(LIQUIDATOR);
        assertEq(endingLiquidatorHealthFactor,startingLiquidatorHealthFactor);
    }

    function test_Liquidate_PaysOutWethToLiquidtor() public liquidationSetup {
        uint256 startingLiquidatorWethBalance = MockERC20WETH(weth).balanceOf(LIQUIDATOR);
        //This test is a complete liquidation so liquidator should get All of the balance
        uint256 userCollateralBalance = dscEngine.getFromCollateralDepositedMapping(USER, weth);
        MockV3Aggregator(wethUsdPriceFeed).updateAnswer(20e8);
        vm.warp(3);

        vm.prank(LIQUIDATOR);
        dscEngine.liquidate(weth, USER, 1000 ether);

        uint256 endingLiquidatorWethBalance = MockERC20WETH(weth).balanceOf(LIQUIDATOR);

        assertEq(endingLiquidatorWethBalance,startingLiquidatorWethBalance + userCollateralBalance);
    }

    //--------------GetTokenAmountFromUsd Tests--------------//

    function test_GetTokenAmountFromUsd_ReturnsCorrectTokenValue() public {
        uint256 usdAmount = 2000 ether; //Usd is provided in wei so 1e18 (1 ether) represents 1 usd
        uint256 expectedWeth = 1 ether; //As the static price from the mock is 1 ETH = $2000 we should get 1 eth as the result
        uint256 actualWeth = dscEngine.getTokenAmountFromUsd(weth, usdAmount);
        assertEq(expectedWeth, actualWeth);
    }

    //--------------GetAccountCollateralValue Tests--------------//

    function test_GetAccountCollateralValue_ReturnsCorrectCollateralValue() public {
        vm.startPrank(USER);
        MockERC20WETH(weth).approve(address(dscEngine), TENETHER);
        MockERC20WBTC(wbtc).approve(address(dscEngine), FIVEBITCOIN);
        dscEngine.depositCollateral(weth, TENETHER);
        dscEngine.depositCollateral(wbtc, FIVEBITCOIN);
        vm.stopPrank();
        uint256 expectedUsd = 25000e18;
        assertEq(dscEngine.getAccountCollateralValue(USER), expectedUsd);
    }

    //--------------GetUsdValue Tests--------------//

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

    //--------------GetCollateralTokenAddresses Tests--------------//
    function test_GetCollateralTokenAddresses_ReturnsCorrectAddesses() public {
        address[] memory collateralTokens = dscEngine.getCollateralTokenAddresses();
        assertEq(weth, collateralTokens[0]);
        assertEq(wbtc, collateralTokens[1]);
    }
}
