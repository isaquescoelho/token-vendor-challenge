// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import { Test } from "forge-std/Test.sol";

import { TokenVendor } from "../src/TokenVendor.sol";
import { BlockfulToken } from "../src/BlockfulToken.sol";

contract TokenVendorTest is Test {
    TokenVendor public vendor;
    BlockfulToken public token;
    address public owner;
    address public user1;

    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 1e18;
    uint256 public constant TOKEN_PRICE = 1e16; // Price per token in wei (0.01 ETH per token)

    receive() external payable {}

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        token = new BlockfulToken(INITIAL_SUPPLY);
        vendor = new TokenVendor(address(token), TOKEN_PRICE);
        token.transfer(address(vendor), INITIAL_SUPPLY);
    }

    function testBuyTokens() public {
        uint256 ethAmount = 1 ether; // User sends 1 ETH
        uint256 expectedTokens = (ethAmount * 1e18) / TOKEN_PRICE; // Should receive 100 tokens (with decimals)

        // Fund user1 with ETH
        vm.deal(user1, ethAmount);

        // User1 buys tokens
        vm.prank(user1);
        vendor.buyTokens{ value: ethAmount }();

        // Check user1's token balance
        assertEq(token.balanceOf(user1), expectedTokens);
        // Check vendor's ETH balance
        assertEq(address(vendor).balance, ethAmount);
    }

    function testSellTokens() public {
        uint256 tokenAmount = 100 * 10 ** 18;
        uint256 expectedEth = tokenAmount / TOKEN_PRICE;

        // First, buy some tokens
        vm.deal(user1, 1 ether);
        vm.startPrank(user1);
        vendor.buyTokens{ value: 1 ether }();

        // Approve vendor to spend tokens
        token.approve(address(vendor), tokenAmount);

        // Sell tokens
        uint256 initialBalance = user1.balance;
        vendor.sellTokens(tokenAmount);
        vm.stopPrank();

        assertEq(token.balanceOf(user1), 0);
        assertEq(user1.balance - initialBalance, expectedEth);
    }

    function testWithdraw() public {
        uint256 ethAmount = 1 ether;

        // First, buy some tokens to add ETH to the vendor
        vm.deal(user1, ethAmount);
        vm.prank(user1);
        vendor.buyTokens{ value: ethAmount }();

        // Withdraw ETH
        uint256 initialBalance = owner.balance;
        vendor.withdraw();

        assertEq(owner.balance - initialBalance, ethAmount);
        assertEq(address(vendor).balance, 0);
    }

    function testBuyTokensEvent() public {
        uint256 ethAmount = 1 ether;
        uint256 expectedTokens = ethAmount * TOKEN_PRICE;

        vm.deal(user1, ethAmount);
        vm.prank(user1);

        vm.expectEmit(true, false, false, true);
        emit TokenVendor.TokensPurchased(user1, ethAmount, expectedTokens);
        vendor.buyTokens{ value: ethAmount }();
    }

    function testSellTokensEvent() public {
        uint256 tokenAmount = 100 * 10 ** 18;
        uint256 expectedEth = tokenAmount / TOKEN_PRICE;

        // First, buy some tokens
        vm.deal(user1, 1 ether);
        vm.startPrank(user1);
        vendor.buyTokens{ value: 1 ether }();

        // Approve vendor to spend tokens
        token.approve(address(vendor), tokenAmount);

        // Sell tokens
        vm.expectEmit(true, false, false, true);
        emit TokenVendor.TokensSold(user1, tokenAmount, expectedEth);
        vendor.sellTokens(tokenAmount);
        vm.stopPrank();
    }

    function testWithdrawEvent() public {
        uint256 ethAmount = 1 ether;

        // First, buy some tokens to add ETH to the vendor
        vm.deal(user1, ethAmount);
        vm.prank(user1);
        vendor.buyTokens{ value: ethAmount }();

        // Withdraw ETH
        vm.expectEmit(true, false, false, true);
        emit TokenVendor.EthWithdrawn(owner, ethAmount);
        vendor.withdraw();
    }
}
