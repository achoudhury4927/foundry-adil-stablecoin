// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {Test} from "forge-std/Test.sol";
import {DecentralisedStableCoin} from "../../src/DecentralisedStableCoin.sol";

contract DecentralisedStableCoinTest is Test {
    DecentralisedStableCoin public ascContract;
    address public user = makeAddr("user");

    function setUp() public {
        ascContract = new DecentralisedStableCoin();
        ascContract.mint(user, 100);
    }

    function test_Mint_IncreasesUsersBalance() public {
        assertEq(100, ascContract.balanceOf(user), "Balance increased by 100");
    }

    function test_Mint_ReturnsTrueOnMint() public {
        assertEq(true, ascContract.mint(user, 100), "Mint returns true");
    }

    function test_Mint_RevertsIf_MintToZeroAddress() public {
        vm.expectRevert(DecentralisedStableCoin.DecentralisedStableCoin__NotZeroAddress.selector);
        ascContract.mint(address(0), 100);
    }

    function test_Mint_RevertsIf_AmountIsZero() public {
        vm.expectRevert(DecentralisedStableCoin.DecentralisedStableCoin__AmountMustBeMoreThanZero.selector);
        ascContract.mint(user, 0);
    }

    function test_Burn_RevertsIf_AmountIsZero() public {
        vm.expectRevert(DecentralisedStableCoin.DecentralisedStableCoin__AmountMustBeMoreThanZero.selector);
        ascContract.burn(0);
    }

    function test_Burn_RevertsIf_AmountIsGreaterThanBalance() public {
        vm.expectRevert(DecentralisedStableCoin.DecentralisedStableCoin__BurnAmountExceedsBalance.selector);
        ascContract.burn(200);
    }

    function test_Burn_ReducesBalance() public {
        ascContract.mint(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496, 100);
        assertEq(100, ascContract.balanceOf(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496), "Balance is 100");
        vm.prank(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496);
        ascContract.burn(99);
        assertEq(1, ascContract.balanceOf(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496), "Balance decreased by 99");
    }
}
