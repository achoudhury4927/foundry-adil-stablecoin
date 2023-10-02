// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {IDSCEngine} from "./IDSCEngine.sol";

/**
 * @title DSCEngine
 * @author Adil Choudhury
 *
 * This system is designed to maintain a token peg of $1 and be as minimal as possible.
 * This stablecoin has the following properties:
 * - Exogenous Collateral
 * - Dollar Pegged
 * - Algorithmically Stable
 *
 * Think DAI without the governance, fees and was only backed by WETH AND WBTC
 *
 * Our DSC system should always be overcollateralised. At no point should the value of all backed ASC be greater than the value of all collateral.
 *
 * @notice This contract is the core of the DSC System. It handles all the logic for minting and redeeming ASC, as well as depositing and withdrawing collateral
 * @notice This contract is loosely based on the MakerDAO DSS (DAI) system.
 */
contract DSCEngine is IDSCEngine {
    function depositCollateralAndMintAsc() external {}

    function depositCollateral() external {}

    function redeemCollateralForAsc() external {}

    function redeemCollateral() external {}

    function mintDsc() external {}

    function burnAsc() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}
}
