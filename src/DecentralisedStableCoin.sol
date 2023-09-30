// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DecentralisedStableCoin
 * @author Adil Choudhury
 * Collateral: Exogenous (List supported by chainlink oracle)
 * Minting: Algorithmic
 * Peg: USD
 *
 * This contract is meant to governed by DSCEngine.sol. This contract is an ERC20 implementation of our stablecoin system.
 */
contract DecentralisedStableCoin is ERC20Burnable, Ownable {
    error DecentralisedStableCoin__AmountMustBeMoreThanZero();
    error DecentralisedStableCoin__BurnAmountExceedsBalance();
    error DecentralisedStableCoin__NotZeroAddress();

    constructor() ERC20("DecentralisedStableCoin", "ASC") {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount < 0) {
            revert DecentralisedStableCoin__AmountMustBeMoreThanZero();
        }
        //Question: Is this required? Line 283 in ERC20.sol has this same require
        //TODO: Test with this code commented out and check behaviour
        if (balance < _amount) {
            revert DecentralisedStableCoin__BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }

    function mint(
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        //Question: Is this required? Line 252 in ERC20.sol has this same require
        //TODO: Test with this code commented out and check behaviour
        if (_to == address(0)) {
            revert DecentralisedStableCoin__NotZeroAddress();
        }
        if (_amount <= 0) {
            revert DecentralisedStableCoin__AmountMustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return true;
    }
}
