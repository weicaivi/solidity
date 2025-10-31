# Masterkey Contract: Ownable + VaultMaster

A clean, modular way to build secure Ethereum smart contracts is to split shared logic (like ownership and access control) from application logic (like deposits and withdrawals). Solidity inheritance lets you do exactly that.

## Why Inheritance Matters
- Avoid duplicating common logic (e.g., ownership checks).
- Keep contracts focused and easier to maintain.
- Reuse audited patterns (e.g., OpenZeppelin’s Ownable).
- Make intent explicit using `virtual` and `override` when customizing inherited functions.


## What We’ll Build
- Ownable.sol — defines the contract owner and provides an `onlyOwner` modifier.
- VaultMaster.sol — a simple ETH vault that allows anyone to deposit, but only the owner to withdraw. It inherits from `Ownable`.

---

## Contract 1: Ownable.sol (Minimal Base)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can perform this action");
        _;
    }

    function ownerAddress() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        address previous = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(previous, newOwner);
    }
}
```

Key points:
- Stores an internal `_owner` and exposes it via `ownerAddress()`.
- `onlyOwner` guards sensitive functions.
- Emits `OwnershipTransferred` for transparent ownership changes.

---

## Contract 2: VaultMaster.sol (ETH Vault with Ownership)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";

contract VaultMaster is Ownable {
    event DepositSuccessful(address indexed account, uint256 value);
    event WithdrawSuccessful(address indexed recipient, uint256 value);

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Accept ETH via explicit deposit
    function deposit() public payable {
        require(msg.value > 0, "Enter a valid amount");
        emit DepositSuccessful(msg.sender, msg.value);
    }

    // Owner-only withdrawal
    function withdraw(address payable to, uint256 amount) public onlyOwner {
        require(to != address(0), "Invalid recipient");
        require(amount <= address(this).balance, "Insufficient balance");

        (bool success, ) = to.call{value: amount}("");
        require(success, "Transfer failed");
        emit WithdrawSuccessful(to, amount);
    }

    // Optional: accept ETH via receive
    receive() external payable {
        require(msg.value > 0, "Enter a valid amount");
        emit DepositSuccessful(msg.sender, msg.value);
    }
}
```

Highlights:
- Public deposits and balance visibility.
- Owner-restricted withdrawals with event logging.
- Uses low-level `call{value: ...}("")` for transfers (preferred over `transfer()` in modern Solidity).

---

## Using OpenZeppelin’s Ownable (Production-Friendly)

To rely on battle-tested code, import OpenZeppelin’s `Ownable`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract VaultMaster is Ownable {
    event DepositSuccessful(address indexed account, uint256 value);
    event WithdrawSuccessful(address indexed recipient, uint256 value);

    // Deployer becomes the initial owner automatically

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function deposit() public payable {
        require(msg.value > 0, "Enter a valid amount");
        emit DepositSuccessful(msg.sender, msg.value);
    }

    function withdraw(address payable to, uint256 amount) public onlyOwner {
        require(to != address(0), "Invalid recipient");
        require(amount <= address(this).balance, "Insufficient balance");

        (bool success, ) = to.call{value: amount}("");
        require(success, "Transfer failed");
        emit WithdrawSuccessful(to, amount);
    }

    receive() external payable {
        require(msg.value > 0, "Enter a valid amount");
        emit DepositSuccessful(msg.sender, msg.value);
    }
}
```

Notes:
- In recent OpenZeppelin versions, the deployer is set as owner by default; no need to pass `msg.sender` in the constructor.
- You get audited access-control logic with minimal code.

---

## Best Practices and Tips
- Prefer modular design: separate access control from business logic.
- Emit events for deposits and withdrawals for on-chain auditability.
- Validate inputs: non-zero addresses, positive amounts, sufficient balances.
- Consider adding non-reentrancy guards for complex flows (OpenZeppelin’s `ReentrancyGuard`).
- Document your interfaces and public functions for clarity.



