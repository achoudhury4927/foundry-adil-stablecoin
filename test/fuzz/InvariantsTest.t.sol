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
import {Handler} from "./Handler.t.sol";

/**
 * @title InvariantsTest
 * @author Adil Choudhury
 * @dev Invariant Tests
 *
 */
contract InvariantsTest is StdInvariant, Test {
    DeployDSC deployer;
    DecentralisedStableCoin dsc;
    DSCEngine dscEngine;
    HelperConfig helperConfig;
    Handler handler;
    address wethUsdPriceFeed;
    address wbtcUsdPriceFeed;
    address weth;
    address wbtc;
    function setUp() external {
        deployer = new DeployDSC();
        (dsc, dscEngine, helperConfig) = deployer.run();
        (wethUsdPriceFeed, wbtcUsdPriceFeed, weth, wbtc,) = helperConfig.activeNetworkConfig();
        // targetContract(address(dscEngine));
        handler = new Handler(dscEngine,dsc);
        targetContract(address(handler));
    }

    function invariant_ProtocolMustHaveMoreValueThanTotalSupply() public view {
        uint256 totalSupply = dsc.totalSupply();
        uint256 totalWethDeposited = MockERC20WETH(weth).balanceOf(address(dscEngine));
        uint256 wethValue = dscEngine.getUsdValue(weth, totalWethDeposited);

        assert(wethValue >= totalSupply);
    }
}
