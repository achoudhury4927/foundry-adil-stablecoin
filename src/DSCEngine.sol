// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {ITestDSCEngine} from "../test/interface/ITestDSCEngine.t.sol";
import {DecentralisedStableCoin} from "./DecentralisedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
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
 * Our DSC system should always be overcollateralised. At no point should the value of all backed Dsc be greater than the value of all collateral.
 *
 * @notice This contract is the core of the DSC System. It handles all the logic for minting and redeeming Dsc, as well as depositing and withdrawing collateral
 * @notice This contract is loosely based on the MakerDAO DSS (DAI) system.
 * @dev Ensure ITestDSCEngine and its implemented functions are removed before deployment
 */

contract DSCEngine is ReentrancyGuard, ITestDSCEngine {
    error DSCEngine_AmountNeedsToBeMoreThanZero();
    error DSCEngine_TokenAddressesAndPriceFeedAddressesMustBeTheSameLength();
    error DSCEngine_NotAllowedToken();
    error DSCEngine_TransferFailed();
    error DSCEngine_BreaksHealthFactor(uint256);
    error DSCEngine_MintFailed();

    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50;
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1;
    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    mapping(address user => uint256 amountDscMinted) private s_DscMinted;
    address[] private s_collateralTokens;

    DecentralisedStableCoin private immutable i_Dsc;

    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
    event CollatedRedeemed(address indexed user, address indexed token, uint256 indexed amount);

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
            s_collateralTokens.push(tokenAddress[i]);
        }

        i_Dsc = DecentralisedStableCoin(decentralisedStableCoinAddress);
    }

    /**
     * @param tokenCollateralAddress The address of the token to deposit as collateral
     * @param amountCollateral The amount of collateral to deposit
     * @param amountDscToMint The amount of decentralised stablecoin to mint
     * @notice This function will deposit collateral and then mint DSC in one transaction
     */
    function depositCollateralAndMintDsc(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountDscToMint
    ) external {
        depositCollateral(tokenCollateralAddress, amountCollateral);
        mintDsc(amountDscToMint);
    }

    /**
     * @param tokenCollateralAddress The address of the token to deposit as collateral
     * @param amountCollateral The amount of collateral to deposit
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);

        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert DSCEngine_TransferFailed();
        }
    }

    function redeemCollateralForDsc(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountOfDscToBurn)
        external
    {
        burnDsc(amountOfDscToBurn);
        redeemCollateral(tokenCollateralAddress, amountCollateral);
    }

    function redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        moreThanZero(amountCollateral)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] -= amountCollateral;
        emit CollatedRedeemed(msg.sender, tokenCollateralAddress, amountCollateral);

        bool success = IERC20(tokenCollateralAddress).transfer(msg.sender, amountCollateral);
        if (!success) {
            revert DSCEngine_TransferFailed();
        }
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    /**
     * @param amountDscToMint The amount of Dsc to mint
     */
    function mintDsc(uint256 amountDscToMint) public moreThanZero(amountDscToMint) nonReentrant {
        s_DscMinted[msg.sender] += amountDscToMint;
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_Dsc.mint(msg.sender, amountDscToMint);
        if (!minted) {
            revert DSCEngine_MintFailed();
        }
    }

    function burnDsc(uint256 amount) public moreThanZero(amount) {
        s_DscMinted[msg.sender] -= amount;
        bool success = i_Dsc.transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert DSCEngine_TransferFailed();
        }
        i_Dsc.burn(amount);
        _revertIfHealthFactorIsBroken(msg.sender); //Can burning debt break health factor?
    }

    function liquidate() external {}

    function getHealthFactor() external view {}

    /*================= TEST FUNCTION FROM ITestDSCEngine REMOVE BEFORE DEPLOY =================*/
    function getFromCollateralDepositedMapping(address userAddress, address tokenCollateralAddress)
        external
        view
        returns (uint256)
    {
        return s_collateralDeposited[userAddress][tokenCollateralAddress];
    }

    /*================= TEST FUNCTION FROM ITestDSCEngine REMOVE BEFORE DEPLOY =================*/
    function getFromPricefeedsMapping(address tokenAddress) external view returns (address) {
        return s_priceFeeds[tokenAddress];
    }

    /*================= TEST FUNCTION FROM ITestDSCEngine REMOVE BEFORE DEPLOY =================*/
    function getFromCollateralTokensArray(uint256 index) external view returns (address) {
        return s_collateralTokens[index];
    }

    /*================= TEST FUNCTION FROM ITestDSCEngine REMOVE BEFORE DEPLOY =================*/
    function getDscAddress() external view returns (address) {
        return address(i_Dsc);
    }

    /*================= TEST FUNCTION FROM ITestDSCEngine REMOVE BEFORE DEPLOY =================*/
    function getFromDSCMintedMapping(address user) external view returns (uint256) {
        return s_DscMinted[user];
    }

    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        totalDscMinted = s_DscMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);
    }

    /**
     * Returns how close to liquidation a user is. If healthfactor <1 they can get liquidated
     * @param user address to check health factor of
     */
    function _healthFactor(address user) private view returns (uint256) {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
    }

    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine_BreaksHealthFactor(userHealthFactor);
        }
    }

    function getAccountCollateralValue(address user) public view returns (uint256) {
        uint256 totalCollateralValueInUsd;
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }
        return totalCollateralValueInUsd;
    }

    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData(); //Price is returned in 1e8 needs to be multiplied by 1e10 to get into same base as wei which is 1e18
        //If 1 ETH = $1000
        //Price will be 1000 * 1e8
        //To get the wei amount (1 ETH = 1 * 1e18)
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION; //Price in 1e18 multiplied by amount, to get 1e18 total, divided by 1e18 to get a dollar amount.
    }
}
