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
    error DSCEngine_AmountNeedsToBeMoreThanZero();
    error DSCEngine_TokenAddressesAndPriceFeedAddressesMustBeTheSameLength();

    mapping(address token => address priceFeed) private s_priceFeeds;

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine_AmountNeedsToBeMoreThanZero();
        }
        _;
    }

    /**Base Goerli Chainlink Pricefeeds:
     * BTC/USD - 0xAC15714c08986DACC0379193e22382736796496f
     * ETH/USD - 0xcD2A119bD1F7DF95d706DE6F2057fDD45A0503E2
     */
    constructor(
        address[] memory tokenAddress,
        address[] memory priceFeedAddress,
        address decentralisedStableCoinAddress
    ) {
        if (tokenAddress.length != priceFeedAddress.length) {
            revert DSCEngine_TokenAddressesAndPriceFeedAddressesMustBeTheSameLength();
        }
        //Question - What are the implications of tokenAddress and priceFeedAddress not being correct
        //         - What if theyre malicious contracts? Can they be malicious if using Chainlink?
    }

    function depositCollateralAndMintAsc() external {}

    /**
     * @param tokenCollateralAddress The address of the token to deposit as collateral
     * @param amountCollateral The amount of collateral to deposit
     */
    function depositCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral
    ) external moreThanZero(amountCollateral) {}

    function redeemCollateralForAsc() external {}

    function redeemCollateral() external {}

    function mintDsc() external {}

    function burnAsc() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}
}
