// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {IDSCEngine} from "./IDSCEngine.sol";
import {DecentralisedStableCoin} from "./DecentralisedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

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
contract DSCEngine is IDSCEngine, ReentrancyGuard {
    error DSCEngine_AmountNeedsToBeMoreThanZero();
    error DSCEngine_TokenAddressesAndPriceFeedAddressesMustBeTheSameLength();
    error DSCEngine_NotAllowedToken();

    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;

    DecentralisedStableCoin private immutable i_asc;

    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine_AmountNeedsToBeMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert DSCEngine_NotAllowedToken();
        }
        _;
    }

    /**
     * Base Goerli Chainlink Pricefeeds:
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
        for (uint256 i = 0; i < tokenAddress.length; i++) {
            s_priceFeeds[tokenAddress[i]] = priceFeedAddress[i];
        }

        i_asc = DecentralisedStableCoin(decentralisedStableCoinAddress);
    }

    function depositCollateralAndMintAsc() external {}

    /**
     * @param tokenCollateralAddress The address of the token to deposit as collateral
     * @param amountCollateral The amount of collateral to deposit
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
    }

    function redeemCollateralForAsc() external {}

    function redeemCollateral() external {}

    function mintDsc() external {}

    function burnAsc() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}
}
