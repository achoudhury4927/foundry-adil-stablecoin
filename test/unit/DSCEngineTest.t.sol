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
    address wethUsdPriceFeed;
    address wbtcUsdPriceFeed;
    address weth;
    address wbtc;

    address public USER = makeAddr("user");
    uint256 public constant TENETHER = 10 ether;
    uint256 public constant FIVEBITCOIN = 5 ether;
    uint256 public constant ONETHOUSANDDSC = 1 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dscEngine, helperConfig) = deployer.run();
        (wethUsdPriceFeed, wbtcUsdPriceFeed, weth, wbtc,) = helperConfig.activeNetworkConfig();
        MockERC20WETH(weth).mint(USER, TENETHER);
        MockERC20WBTC(wbtc).mint(USER, FIVEBITCOIN);
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

    //--------------DepositCollateralAndMintDsc Tests--------------//

    function test_DepositCollateralAndMintDsc_TransfersCollateralToDSCEngine() public {
        vm.startPrank(USER);
        MockERC20WETH(weth).approve(address(dscEngine), TENETHER);
        dscEngine.depositCollateralAndMintDsc(weth, TENETHER, ONETHOUSANDDSC);
        assertEq(TENETHER, dscEngine.getFromCollateralDepositedMapping(USER, weth));
        assertEq(ONETHOUSANDDSC, dscEngine.getFromDSCMintedMapping(USER));
        assertEq(dsc.balanceOf(USER), ONETHOUSANDDSC);
        vm.stopPrank();
    }

    //--------------DepositCollateral Tests--------------//

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
        //dscEngine.depositCollateral(weth, TENETHER)
    }

    function test_DepositCollateral_CollateralDespoitedMappingIsUpated() public {
        vm.startPrank(USER);
        MockERC20WETH(weth).approve(address(dscEngine), TENETHER);
        dscEngine.depositCollateral(weth, TENETHER);
        assertEq(TENETHER, dscEngine.getFromCollateralDepositedMapping(USER, weth));
        vm.stopPrank();
    }

    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    function test_DepositCollateral_EmitsCollateralDeposited() public {
        vm.startPrank(USER);
        MockERC20WETH(weth).approve(address(dscEngine), TENETHER);
        vm.expectEmit(true, true, true, true);
        emit CollateralDeposited(USER, weth, TENETHER);
        dscEngine.depositCollateral(weth, TENETHER);
        vm.stopPrank();
    }

    function test_DepositCollateral_TransfersCollateralToDSCEngine() public {
        vm.startPrank(USER);
        MockERC20WETH(weth).approve(address(dscEngine), TENETHER);
        dscEngine.depositCollateral(weth, TENETHER);
        assertEq(TENETHER, MockERC20WETH(weth).balanceOf(address(dscEngine)));
        vm.stopPrank();
    }
    //--------------MintDsc Tests--------------//

    function test_MintDsc_UpdatesDscMintedMapping() public {
        vm.startPrank(USER);
        MockERC20WETH(weth).approve(address(dscEngine), TENETHER);
        dscEngine.depositCollateral(weth, TENETHER);
        dscEngine.mintDsc(ONETHOUSANDDSC);
        assertEq(ONETHOUSANDDSC, dscEngine.getFromDSCMintedMapping(USER));
        vm.stopPrank();
    }

    function test_MintDsc_RevertsIf_HealthFactorIsBroken() public {
        vm.startPrank(USER);
        MockERC20WETH(weth).approve(address(dscEngine), TENETHER);
        dscEngine.depositCollateral(weth, 1 ether);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine_BreaksHealthFactor.selector, 1000));
        dscEngine.mintDsc(ONETHOUSANDDSC * 1 ether);
        vm.stopPrank();
    }

    //--------------RedeemCollateralForDsc Tests--------------//

    function test_RedeemCollateralForDsc_TransfersCollateralToUser() public {
        vm.startPrank(USER);
        MockERC20WETH(weth).approve(address(dscEngine), TENETHER);
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

    function test_RedeemCollateral_RevertsIfHealthFactorIsBroken() public {
        vm.startPrank(USER);
        MockERC20WETH(weth).approve(address(dscEngine), TENETHER);
        dsc.approve(address(dscEngine), TENETHER);
        dscEngine.depositCollateralAndMintDsc(weth, TENETHER, ONETHOUSANDDSC);
        assertEq(TENETHER, dscEngine.getFromCollateralDepositedMapping(USER, weth));
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine_BreaksHealthFactor.selector, 0));
        dscEngine.redeemCollateral(weth, TENETHER);
        vm.stopPrank();
    }

    function test_RedeemCollateral_UpdatesCollateralDepositedMapping() public {
        vm.startPrank(USER);
        MockERC20WETH(weth).approve(address(dscEngine), TENETHER);
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

    function test_RedeemCollateral_EmitsCollateralRedeemed() public {
        vm.startPrank(USER);
        MockERC20WETH(weth).approve(address(dscEngine), TENETHER);
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

    function test_BurnDsc_UpdatesDSCMintedMapping() public {
        vm.startPrank(USER);
        MockERC20WETH(weth).approve(address(dscEngine), TENETHER);
        dsc.approve(address(dscEngine), TENETHER);
        dscEngine.depositCollateralAndMintDsc(weth, TENETHER, ONETHOUSANDDSC);
        assertEq(ONETHOUSANDDSC, dscEngine.getFromDSCMintedMapping(USER));
        dscEngine.burnDsc(ONETHOUSANDDSC);
        assertEq(0, dscEngine.getFromDSCMintedMapping(USER));
        vm.stopPrank();
    }

    function test_BurnDsc_ReducesDSCBalanceCorrectly() public {
        vm.startPrank(USER);
        MockERC20WETH(weth).approve(address(dscEngine), TENETHER);
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
}
