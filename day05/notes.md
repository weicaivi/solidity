# Admin-Only Access Control

A common real-world requirement is to restrict certain actions to an administrator (owner). Think of a game where only the admin distributes rewards, or a treasury where only one address approves withdrawals. This demo shows how to implement owner-only functions using a Solidity modifier and a simple “treasure chest” example.

## What We're Building
- How to set and use an owner address
- How to write an `onlyOwner` modifier for reusable access control
- How to manage allowances and single-use withdrawals
- How to transfer ownership safely
- How to add small improvements (events, view helpers)

## Contract Overview

We’ll build an `AdminOnly` contract with:
- Owner-controlled actions: add treasure, approve withdrawals, reset user status, transfer ownership, view treasure details
- User action: withdraw treasure, with checks for allowance, prior withdrawal, and treasury balance

## Complete Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AdminOnly {
    // ========== Owner Setup ==========
    address public owner;

    constructor() {
        owner = msg.sender; // Deployer becomes the owner
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied: Only owner");
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

    // Track one-time withdrawal per user
    mapping(address => bool) public hasWithdrawn;

    // ========== Withdraw Logic ==========
    function withdrawTreasure(uint256 amount) public {
        // Case 1: Owner withdrawing
        if (msg.sender == owner) {
            require(amount <= treasureAmount, "Not enough treasure");
            treasureAmount -= amount;
            return;
        }

        // Case 2: Regular user
        uint256 allowance = withdrawalAllowance[msg.sender];
        require(allowance > 0, "No allowance");
        require(!hasWithdrawn[msg.sender], "Already withdrawn");
        require(allowance <= treasureAmount, "Not enough treasure");

        hasWithdrawn[msg.sender] = true;
        treasureAmount -= allowance;
        withdrawalAllowance[msg.sender] = 0;

        // Note: No token transfer here—this is a logic demo contract.
    }

    // ========== Admin Utilities ==========
    function resetWithdrawalStatus(address user) public onlyOwner {
        hasWithdrawn[user] = false;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        owner = newOwner;
    }

    // Owner-only view for details (can be public if desired)
    function getTreasureDetails() public view onlyOwner returns (uint256) {
        return treasureAmount;
    }

    // Optional: public helper so users can check their status
    function getMyAllowance() external view returns (uint256) {
        return withdrawalAllowance[msg.sender];
    }

    function hasUserWithdrawn(address user) external view returns (bool) {
        return hasWithdrawn[user];
    }
}
```

## Highlights

### Owner and Modifier
- `owner`: The deployer address set in the constructor (`msg.sender`).
- `onlyOwner`: A reusable guard that reverts calls from non-owners, keeping code DRY and secure.

### Treasure Management
- `treasureAmount`: A `uint256` that represents the current “treasure” balance.
- `addTreasure(amount)`: Owner increases the treasure chest.

### Approvals and One-Time Withdrawals
- `withdrawalAllowance[address]`: Maps each address to an approved amount.
- `approveWithdrawal(recipient, amount)`: Owner sets user allowance, ensuring the chest holds enough.
- `hasWithdrawn[address]`: Flags whether a user has already withdrawn once.
- `withdrawTreasure(amount)`:
  - Owner path: can withdraw any amount up to `treasureAmount`.
  - User path: must have allowance, must not have withdrawn before, and chest must have enough treasure. On success, the contract marks the user as withdrawn, subtracts the allowance, and resets it.

### Admin Utilities
- `resetWithdrawalStatus(user)`: Owner can reset a user’s withdrawal flag to allow another withdrawal cycle.
- `transferOwnership(newOwner)`: Safely hand over control, preventing zero address assignments.
- `getTreasureDetails()`: Owner-only view of treasure.

## Why This Pattern Matters
- Centralized control for critical operations (minting, approvals, admin actions).
- Clear separation between admin and user flows via modifiers and checks.
- Mappings track per-user permissions and status with minimal storage.

## Suggested Improvements
- Emit events for key actions:
  - `TreasureAdded(amount)`
  - `WithdrawalApproved(recipient, amount)`
  - `TreasureWithdrawn(user, amount)`
  - `OwnershipTransferred(oldOwner, newOwner)`
- Add a cooldown: track a `lastWithdrawAt[address]` and enforce `block.timestamp >= last + cooldown`.
- Add maximum per-user limits independent of current chest balance.
- Consider OpenZeppelin’s `Ownable` for standardized ownership utilities in production.

## Testing Tips (Remix)
1. Deploy the contract. Confirm `owner` equals your address.
2. Call `addTreasure(100)` as owner.
3. Approve a user: `approveWithdrawal(0xUser, 50)`.
4. As the approved user, call `withdrawTreasure(0)` or `withdrawTreasure(50)`.
5. Attempt a second withdrawal—should fail unless `resetWithdrawalStatus` is called by the owner.
6. Transfer ownership and verify that only the new owner can call admin functions.

## Key Concepts Recap
- `msg.sender`: The caller of the function; used to verify permissions.
- Modifiers: Reusable checks that prepend function execution.
- Mappings and flags: Lightweight, per-user state management.
- Owner-only admin panel: A pattern you’ll see in tokens, NFT minting, treasuries, and governance.