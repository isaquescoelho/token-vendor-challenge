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

    function buyTokens() public payable {
        // Implement buying logic
    }

    function sellTokens(uint256 _amount) public {
        // Implement selling logic
    }

    function withdraw() public {
        // Implement withdrawal logic
    }

    // Add any additional functions here
}
