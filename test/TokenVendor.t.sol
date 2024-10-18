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
        uint256 tokenAmount = 100 * 1e18; // User wants to sell 100 tokens
        uint256 expectedEth = (tokenAmount * TOKEN_PRICE) / 1e18; // Should receive 1 ETH

        // First, buy tokens
        vm.deal(user1, expectedEth); // User1 needs ETH to buy tokens
        vm.startPrank(user1);

        vendor.buyTokens{ value: expectedEth }();

        // Approve vendor to spend tokens
        token.approve(address(vendor), tokenAmount);

        uint256 initialBalance = user1.balance;

        // Sell tokens
        vendor.sellTokens(tokenAmount);

        vm.stopPrank();

        // Check user1's token balance
        assertEq(token.balanceOf(user1), 0);
        // Check user1's ETH balance change
        assertEq(user1.balance - initialBalance, expectedEth);
    }

    function testWithdraw() public {
        uint256 ethAmount = 1 ether;

        vm.deal(user1, ethAmount);
        vm.prank(user1);
        vendor.buyTokens{ value: ethAmount }();

        uint256 initialBalance = owner.balance;
        vendor.withdraw();

        assertEq(owner.balance - initialBalance, ethAmount);
        assertEq(address(vendor).balance, 0);
    }

    function testBuyTokensEvent() public {
        uint256 ethAmount = 1 ether;
        uint256 expectedTokens = (ethAmount * 1e18) / TOKEN_PRICE;

        vm.deal(user1, ethAmount);
        vm.prank(user1);

        vm.expectEmit(true, true, false, true);
        emit TokensPurchased(user1, ethAmount, expectedTokens);

        vendor.buyTokens{ value: ethAmount }();
    }

    function testSellTokensEvent() public {
        uint256 tokenAmount = 100 * 1e18;
        uint256 expectedEth = (tokenAmount * TOKEN_PRICE) / 1e18;

        vm.deal(user1, expectedEth);
        vm.startPrank(user1);

        vendor.buyTokens{ value: expectedEth }();

        // Approve vendor to spend tokens
        token.approve(address(vendor), tokenAmount);

        // Expect the TokensSold event
        vm.expectEmit(true, true, false, true);
        emit TokensSold(user1, tokenAmount, expectedEth);

        vendor.sellTokens(tokenAmount);

        vm.stopPrank();
    }

    function testWithdrawEvent() public {
        uint256 ethAmount = 1 ether;

        // User1 buys tokens to add ETH to vendor
        vm.deal(user1, ethAmount);
        vm.prank(user1);
        vendor.buyTokens{ value: ethAmount }();

        // Expect the EthWithdrawn event
        vm.expectEmit(true, true, false, true);
        emit EthWithdrawn(owner, ethAmount);

        // Owner withdraws ETH from vendor
        vendor.withdraw();
    }

    function testBuyAndSellTokens() public {
        uint256 ethAmount = 1 ether;
        uint256 expectedTokens = (ethAmount * 1e18) / TOKEN_PRICE;

        // Usuário compra tokens
        vm.deal(user1, ethAmount);
        vm.startPrank(user1);
        vendor.buyTokens{ value: ethAmount }();

        assertEq(token.balanceOf(user1), expectedTokens);

        // Usuário vende tokens
        token.approve(address(vendor), expectedTokens);
        vendor.sellTokens(expectedTokens);

        assertEq(token.balanceOf(user1), 0);
        assertEq(user1.balance, ethAmount);
    }

    function testHighGasUsage() public {
        uint256 ethAmount = 1 ether;
        vm.deal(user1, ethAmount);
        vm.startPrank(user1);

        // Comprar tokens usando uma quantidade alta de gás
        vendor.buyTokens{ value: ethAmount, gas: 5000000 }();
    }


    function testMultipleUsersBuying() public {
        for (uint i = 1; i <= 10; i++) {
            address user = address(uint160(i));
            vm.deal(user, 1 ether);
            vm.startPrank(user);
            vendor.buyTokens{ value: 1 ether }();
            vm.stopPrank();
        }
    }

    function testMaximumETHBuy() public {
        uint256 maxETH = type(uint256).max; // O valor máximo de uint256
        vm.deal(user1, maxETH);
        vm.startPrank(user1);

        // Não esperamos um revert aqui, mas é bom verificar se a quantidade calculada é razoável
        vendor.buyTokens{ value: maxETH }();
    }

    function testOnlyOwnerSetTokenPrice() public {
        vm.prank(user1); // Impersona um usuário que não é o proprietário
        vm.expectRevert("Only owner can call this function");
        vendor.setTokenPrice(2e16); // Tenta alterar o preço dos tokens
    }

    function testOnlyOwnerWithdraw() public {
        vm.prank(user1); // Impersona um usuário que não é o proprietário
        vm.expectRevert("Only owner can call this function");
        vendor.withdraw(); // Tenta fazer o saque
    }

    function testZeroTokenTransfer() public {
        vm.deal(user1, 1 ether);
        vm.startPrank(user1);
        vm.expectRevert("You need to send ETH to buy tokens");
        vendor.buyTokens{ value: 0 }();
        vm.stopPrank();
    }

    function testZeroTokenSell() public {
        vm.prank(user1);
        vm.expectRevert("You need to sell at least some tokens");
        vendor.sellTokens(0);
    }

    function testWithdrawWithoutBalance() public {
        vm.expectRevert("No ETH to withdraw");
        vendor.withdraw();
    }

    // Define the events used in the tests
    event TokensPurchased(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event TokensSold(address seller, uint256 amountOfTokens, uint256 amountOfETH);
    event EthWithdrawn(address owner, uint256 amount);
}
