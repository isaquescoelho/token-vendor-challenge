// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/TokenVendor.sol";
import "../src/BlockfulToken.sol";
import "../src/ReentrancyAttack.sol";

contract ReentrancyAttackTest is Test {
    TokenVendor public vendor;
    BlockfulToken public token;
    ReentrancyAttack public attacker;
    address public owner;

    function setUp() public {
        owner = address(this);

        token = new BlockfulToken(1_000_000);

        vendor = new TokenVendor(address(token), 1e16);

        token.transfer(address(vendor), token.balanceOf(owner));

        attacker = new ReentrancyAttack(address(vendor), address(token));

        vm.deal(address(attacker), 10 ether);
    }

    function testReentrancyAttack() public {
        vm.expectRevert("Failed to send ETH to the user");
        vm.prank(address(attacker));

        attacker.run{value: 10 ether}();
    }
}
