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

    function test_Mint_RevertsIf_MintToZeroAddress() public {
        vm.expectRevert(
            DecentralisedStableCoin
                .DecentralisedStableCoin__NotZeroAddress
                .selector
        );
        ascContract.mint(address(0), 100);
    }

    function test_Mint_RevertsIf_AmountIsZero() public {
        vm.expectRevert(
            DecentralisedStableCoin
                .DecentralisedStableCoin__AmountMustBeMoreThanZero
                .selector
        );
        ascContract.mint(user, 0);
    }
}
