# Ether Piggy Bank

A guide to building a shared savings “piggy bank” on Ethereum with Solidity. We’ll design roles (manager and members), track balances, accept real Ether, and prepare for safe withdrawals.

## Overview

We’ll build a club-only piggy bank:
- A bank manager approves members.
- Approved members can deposit and view balances.
- The contract can accept real Ether (`msg.value` via `payable` functions).
- We’ll learn clean structure first (simulation), then real ETH handling.


## Core Concepts

- `msg.sender`: identifies the caller (manager or member).
- Modifiers: reusable access checks for safety and clarity.
- `mapping` and `array`: maintain fast membership checks and readable lists.
- `payable` and `msg.value`: enable receiving real Ether.
- Checks-Effects-Interactions: standard pattern for safe withdrawals.

## Contract Design

### State

- `bankManager`: the admin who can approve members.
- `members`: array of all approved addresses (for easy listing).
- `registeredMembers`: mapping for constant-time membership checks.
- `balance`: mapping of address -> amount deposited (supports both simulated units and wei).

### Constructor

- Sets `bankManager` to the deployer.
- Adds the deployer to `members` (the manager is also a member).

### Modifiers

- `onlyBankManager`: restricts administrative actions (e.g., adding members).
- `onlyRegisteredMember`: restricts member actions (e.g., deposit, withdraw, view).

### Membership

- `addMembers(address _member)`: manager-only; validates address, prevents duplicates, stores approval in mapping and array.
- `getMembers()`: public view; returns the full member list.

### Deposits (Simulation First)

- `deposit(uint256 _amount)`: member-only; validates `_amount > 0`, increments `balance[msg.sender]`. No ETH transfer—just logic testing.

### Withdrawals (Simulation)

- `withdraw(uint256 _amount)`: member-only; requires sufficient balance and deducts. Still no ETH transfer—internal accounting only.

### Real Ether Deposits

- `depositAmountEther() payable`: member-only; requires `msg.value > 0`, credits `balance[msg.sender] += msg.value`. Ether stays in the contract balance.

### Safe Withdrawal

When you’re ready to move to actual ETH withdrawals:
- Validate requested amount.
- Use Checks-Effects-Interactions:
  1) Check inputs and balance.
  2) Update storage (deduct).
  3) Transfer with low-level `call` and check success.
- Optionally add a simple reentrancy guard (`nonReentrant`) if you later introduce external calls in modifiers or hooks.

## Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EtherPiggyBank {
    // 1) Roles and membership
    address public bankManager;
    address[] private members;
    mapping(address => bool) public registeredMembers;

    // 2) Balances (simulation units OR wei for ETH deposits)
    mapping(address => uint256) private balance;

    // (Optional) Simple reentrancy guard for future ETH withdrawals
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "Reentrancy");
        _locked = true;
        _;
        _locked = false;
    }

    // Constructor: initialize manager and add as first member
    constructor() {
        bankManager = msg.sender;
        registeredMembers[msg.sender] = true;
        members.push(msg.sender);
    }

    // Modifiers
    modifier onlyBankManager() {
        require(msg.sender == bankManager, "Only bank manager");
        _;
    }

    modifier onlyRegisteredMember() {
        require(registeredMembers[msg.sender], "Not a registered member");
        _;
    }

    // Admin: Add members
    function addMembers(address _member) public onlyBankManager {
        require(_member != address(0), "Invalid address");
        require(_member != msg.sender, "Manager already a member");
        require(!registeredMembers[_member], "Already registered");
        registeredMembers[_member] = true;
        members.push(_member);
    }

    // View: Members list
    function getMembers() public view returns (address[] memory) {
        return members;
    }

    // Simulation deposit (no ETH, just accounting)
    function deposit(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0, "Amount must be > 0");
        balance[msg.sender] += _amount;
    }

    // Simulation withdraw (no ETH transfer)
    function withdraw(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0, "Amount must be > 0");
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        balance[msg.sender] -= _amount;
    }

    // Real Ether deposit
    function depositAmountEther() public payable onlyRegisteredMember {
        require(msg.value > 0, "Amount must be > 0");
        balance[msg.sender] += msg.value;
        // Ether stays in contract; balance tracks per-user deposits (in wei)
    }

    // Optional: Real Ether withdraw (enable when ready)
    function withdrawEther(uint256 amountWei) public onlyRegisteredMember nonReentrant {
        require(amountWei > 0, "Amount must be > 0");
        require(balance[msg.sender] >= amountWei, "Insufficient balance");

        // Checks-Effects-Interactions
        balance[msg.sender] -= amountWei;

        (bool ok, ) = msg.sender.call{value: amountWei}("");
        require(ok, "Transfer failed");
    }

    // Views
    function getMyBalance() external view onlyRegisteredMember returns (uint256) {
        return balance[msg.sender];
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
```

## How to Use in Remix

1. Create a new Solidity file, paste the contract, and compile with 0.8.20+.
2. Deploy.
3. As the manager (deployer), call `addMembers(address)` to approve friends.
4. Members:
   - Use `deposit(uint256)` to simulate deposits.
   - Use `depositAmountEther()` with an ETH value in the transaction to deposit real Ether.
   - Check balances with `getMyBalance()`.
5. When you enable real withdrawals, test `withdrawEther(amountWei)`:
   - Try small amounts first (e.g., 0.01 ETH).
   - Verify `getContractBalance()` before and after.

## Best Practices

- Restrict sensitive actions with modifiers (admin vs. member).
- Use mappings for constant-time checks; arrays for readability in UIs.
- For ETH withdrawals, apply Checks-Effects-Interactions and consider a simple `nonReentrant` guard.
- Emit events (optional enhancement) for deposits/withdrawals to simplify tracking.
- Prefer `call{value: ...}` over `transfer()` due to gas stipend differences.

## Extensions You Can Add

- Event logging: `Deposited` and `Withdrawn` for traceability.
- Withdrawal limits or cooldowns for savings discipline.
- Manager-approved withdrawal requests for group governance.
- Emergency pause (`circuit breaker`) controlled by the manager.
- Per-member caps and group totals for budgeting dashboards.

