// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

interface IToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenVendor {
    IToken public token;
    address public owner;
    uint256 public tokenPrice; // Price per token in wei

    event TokensPurchased(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event TokensSold(address seller, uint256 amountOfTokens, uint256 amountOfETH);
    event EthWithdrawn(address owner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(address _token, uint256 _tokenPrice) {
        token = IToken(_token);
        tokenPrice = _tokenPrice; // Set the price per token in wei
        owner = msg.sender;
    }

    // Function to buy tokens
    function buyTokens() public payable {
        require(msg.value > 0, "You need to send ETH to buy tokens");

        // Calculate the maximum possible tokens that can be bought without causing overflow
        uint256 amountToBuy = msg.value / tokenPrice; // Divide first to avoid overflow
        require(amountToBuy <= type(uint256).max / 1e18, "ETH amount too large");

        amountToBuy = amountToBuy * 1e18; // Safe to multiply now

        uint256 vendorBalance = token.balanceOf(address(this));
        require(vendorBalance >= amountToBuy, "Vendor has not enough tokens");

        bool sent = token.transfer(msg.sender, amountToBuy);
        require(sent, "Token transfer failed");

        emit TokensPurchased(msg.sender, msg.value, amountToBuy);
    }

    }

    // Add any additional functions here
}
