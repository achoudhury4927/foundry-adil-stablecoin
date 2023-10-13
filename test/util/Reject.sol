// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

/**
 * @title Reject
 * @author Adil Choudhury
 * @dev This is a test utility to reject a transaction to test failed transfers
 *
 */
contract Reject {
    receive() external payable {
        revert("Recieve function");
    }

    fallback() external payable {
        revert("Fallback function");
    }
}
