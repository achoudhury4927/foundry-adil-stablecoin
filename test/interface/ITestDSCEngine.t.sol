// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

/**
 * @title IDSCEngine
 * @author Adil Choudhury
 * @dev Interface to expose private variables for the sake of tests only in DSCEngine. Will be removed before deployment.
 *
 */
interface ITestDSCEngine {
    function getFromCollateralDepositedMapping(address, address) external returns (uint256);
    function getFromPricefeedsMapping(address) external returns (address);
    function getFromCollateralTokensArray(uint256) external returns (address);
    function getDscAddress() external returns (address);
    function getFromDSCMintedMapping(address user) external view returns (uint256);
}
