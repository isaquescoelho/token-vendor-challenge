// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

interface IToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract TokenVendor {
    IToken public token;
    address public owner;
    uint256 public tokenPrice;

    bool private locked;

    event TokensPurchased(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event TokensSold(address seller, uint256 amountOfTokens, uint256 amountOfETH);
    event EthWithdrawn(address owner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier nonReentrant() {
        require(!locked, "Reentrancy detected");
        locked = true;
        _;
        locked = false;
    }

    constructor(address _token, uint256 _tokenPrice) {
        token = IToken(_token);
        tokenPrice = _tokenPrice;
        owner = msg.sender;
    }

    function buyTokens() public payable nonReentrant {
        require(msg.value > 0, "You need to send ETH to buy tokens");

        uint256 amountToBuy = (msg.value * 1e18) / tokenPrice;
        uint256 vendorBalance = token.balanceOf(address(this));

        require(vendorBalance >= amountToBuy, "Vendor has not enough tokens");

        bool sent = token.transfer(msg.sender, amountToBuy);
        require(sent, "Token transfer failed");

        emit TokensPurchased(msg.sender, msg.value, amountToBuy);
    }

    function sellTokens(uint256 tokenAmount) public nonReentrant {
        require(tokenAmount > 0, "You need to sell at least some tokens");

        uint256 userBalance = token.balanceOf(msg.sender);
        require(userBalance >= tokenAmount, "Insufficient token balance");

        uint256 ethAmount = (tokenAmount * tokenPrice) / 1e18;
        require(ethAmount <= address(this).balance, "Vendor has not enough ETH");

        bool sent = token.transferFrom(msg.sender, address(this), tokenAmount);
        require(sent, "Failed to transfer tokens from user to vendor");

        (bool success, ) = payable(msg.sender).call{value: ethAmount}("");
        require(success, "Failed to send ETH to the user");

        emit TokensSold(msg.sender, tokenAmount, ethAmount);
    }

    function withdraw() public onlyOwner nonReentrant {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No ETH to withdraw");

        (bool success, ) = payable(owner).call{value: contractBalance}("");
        require(success, "Failed to withdraw ETH");

        emit EthWithdrawn(owner, contractBalance);
    }

    function setTokenPrice(uint256 _newPrice) public onlyOwner {
        require(_newPrice > 0, "Price must be greater than zero");
        tokenPrice = _newPrice;
    }
}
