// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {Test} from "forge-std/Test.sol";
import {DecentralisedStableCoin} from "../../src/DecentralisedStableCoin.sol";

contract DecentralisedStableCoinTest is Test {
    DecentralisedStableCoin public DscContract;
    address public user = makeAddr("user");

    function setUp() public {
        DscContract = new DecentralisedStableCoin();
        DscContract.mint(user, 100);
    }

    function test_Mint_IncreasesUsersBalance() public {
        assertEq(100, DscContract.balanceOf(user), "Balance increased by 100");
    }

    function test_Mint_ReturnsTrueOnMint() public {
        assertEq(true, DscContract.mint(user, 100), "Mint returns true");
    }

    function test_Mint_RevertsIf_MintToZeroAddress() public {
        vm.expectRevert(DecentralisedStableCoin.DecentralisedStableCoin__NotZeroAddress.selector);
        DscContract.mint(address(0), 100);
    }

    function test_Mint_RevertsIf_AmountIsZero() public {
        vm.expectRevert(DecentralisedStableCoin.DecentralisedStableCoin__AmountMustBeMoreThanZero.selector);
        DscContract.mint(user, 0);
    }

    function test_Burn_RevertsIf_AmountIsZero() public {
        vm.expectRevert(DecentralisedStableCoin.DecentralisedStableCoin__AmountMustBeMoreThanZero.selector);
        DscContract.burn(0);
    }

    function test_Burn_RevertsIf_AmountIsGreaterThanBalance() public {
        vm.expectRevert(DecentralisedStableCoin.DecentralisedStableCoin__BurnAmountExceedsBalance.selector);
        DscContract.burn(200);
    }

    function test_Burn_ReducesBalance() public {
        DscContract.mint(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496, 100);
        assertEq(100, DscContract.balanceOf(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496), "Balance is 100");
        vm.prank(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496);
        DscContract.burn(99);
        assertEq(1, DscContract.balanceOf(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496), "Balance decreased by 99");
    }
}
