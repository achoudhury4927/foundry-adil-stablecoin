// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

/**
 * @title IDSCEngine
 * @author Adil Choudhury
 * @dev Interface of the DSCEngine as defined in the Dsc documentation
 *
 */
interface IDSCEngine {
    function depositCollateralAndMintDsc() external;

    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral) external;

    function redeemCollateralForDsc() external;

    function redeemCollateral() external;

    function mintDsc(uint256 amountDscToMint) external;

    function burnDsc() external;

    function liquidate() external;

    function getHealthFactor() external view;
}
