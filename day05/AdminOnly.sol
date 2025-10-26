// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
    // ========== Owner Setup ==========
    address public owner;

    constructor() {
        owner = msg.sender; // deployer becomes owner
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied: Only owner can perform this action");
        _;
    }

    // ========== Treasure Storage ==========
    uint256 public treasureAmount;

    function addTreasure(uint256 amount) public onlyOwner {
        treasureAmount += amount;
    }

    // ========== Withdrawal Approvals ==========
    mapping(address => uint256) public withdrawalAllowance;

    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner {
        require(amount <= treasureAmount, "Insufficient treasure");
        withdrawalAllowance[recipient] = amount;
    }

    // Track one-time withdrawl per user
    mapping(address => bool) public hasWithdrawn;

    // ========== Withdraw Logic ==========
    function withdrawTreasure(uint256 amount) public {
        // case 1: owner withdrawing
        if (msg.sender == owner) {
            require(amount <= treasureAmount, "Not enough treasure");
            treasureAmount -= amount;
            return;
        }

        // case 2: regular user
        uint256 allowance = withdrawalAllowance[msg.sender];
        require(allowance > 0, "No allownce");
        require(!hasWithdrawn[msg.sender], "Already withdrawn");

        hasWithdrawn[msg.sender] = true;
        treasureAmount -= amount;
        withdrawalAllowance[msg.sender] = 0;
    }


    // ========== Admin Utilities ==========
    function resetWithdrawalStatus(address user) public onlyOwner {
        hasWithdrawn[user] = false;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new ownder");
        owner = newOwner;
    }
    
    // owner-only view for details (can be public if desired)
    function getTreasureDetails() public view onlyOwner returns (uint256) {
        return treasureAmount;
    }

    // public helper so users can check their status
    function getMyAllowance() external view returns (uint256) {
        return withdrawalAllowance[msg.sender];
    }

    function hasUserWithdrawn(address user) external view returns (bool) {
        return hasWithdrawn[user];
    }

}