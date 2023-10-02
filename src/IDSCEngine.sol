// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

/**
 * @title IDSCEngine
 * @author Adil Choudhury
 * @dev Interface of the DSCEngine as defined in the ASC documentation
 *
 */
interface IDSCEngine {
    function depositCollateralAndMintAsc() external;

    function depositCollateral() external;

    function redeemCollateralForAsc() external;

    function redeemCollateral() external;

    function mintDsc() external;

    function burnAsc() external;

    function liquidate() external;

    function getHealthFactor() external view;
}
