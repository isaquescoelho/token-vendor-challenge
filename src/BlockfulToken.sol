// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

contract BlockfulToken {
    string public name = "Blockful Token";
    string public symbol = "BFT";
    uint8 public decimals = 18;
    uint256 public initialSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 _initialSupply) {
        initialSupply = _initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = initialSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        // Implement balanceOf logic
    }

    function approve(address spender, uint256 amount) public {
        // Implement approve logic
    }
}
