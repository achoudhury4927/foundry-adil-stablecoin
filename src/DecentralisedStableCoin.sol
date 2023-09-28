// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title DecentralisedStableCoin
 * @author Adil Choudhury
 * Collateral: Exogenous (List supported by chainlink oracle)
 * Minting: Algorithmic
 * Peg: USD
 *
 * This contract is meant to governed by DSCEngine.sol. This contract is an ERC20 implementation of our stablecoin system.
 */
contract DecentralisedStableCoin is ERC20Burnable {
    constructor() ERC20("DecentralisedStableCoin", "ASC") {}
}
