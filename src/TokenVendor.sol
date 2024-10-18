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

    // Function to sell tokens back to the contract
    function sellTokens(uint256 tokenAmount) public {
        require(tokenAmount > 0, "You need to sell at least some tokens");

        uint256 userBalance = token.balanceOf(msg.sender);
        require(userBalance >= tokenAmount, "Insufficient token balance");

        // Calculate the amount of ETH to send to the user, dividing first to avoid overflow
        uint256 ethAmount = (tokenAmount / 1e18) * tokenPrice;
        require(ethAmount <= address(this).balance, "Vendor has not enough ETH");

        bool sent = token.transferFrom(msg.sender, address(this), tokenAmount);
        require(sent, "Failed to transfer tokens from user to vendor");

        (bool success, ) = payable(msg.sender).call{value: ethAmount}("");
        require(success, "Failed to send ETH to the user");

        emit TokensSold(msg.sender, tokenAmount, ethAmount);
    }

    // Function for the owner to withdraw ETH from the contract
    function withdraw() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No ETH to withdraw");

        (bool success, ) = payable(owner).call{value: contractBalance}("");
        require(success, "Failed to withdraw ETH");

        emit EthWithdrawn(owner, contractBalance);
    }

}
