# Simple IOU Contract — A Beginner-Friendly On‑Chain Group Ledger

Manage shared expenses with friends—without spreadsheets or confusion. SimpleIOU is a Solidity smart contract that helps small, private groups track IOUs, hold ETH in in‑app balances, and settle up cleanly.

## What SimpleIOU Solves
When one person pays for group expenses, others promise “I’ll pay you back later.” Over time you get questions like:
- “How much do I owe you?”
- “Did I already repay you?”
- “What’s the total you covered?”
SimpleIOU keeps a transparent, on‑chain ledger of debts and balances so settling up is fast and unambiguous.

## Overview
- Private group: only the owner can register friends (a whitelist).
- In‑app balances: members deposit ETH to the contract.
- Debt tracking: who owes whom, and how much.
- Settlement: pay debts from in‑app balance or transfer ETH out.
- Withdrawals: move ETH from your in‑app balance back to your wallet.

## Contract Architecture

### State Variables
- `owner`: address of the contract admin (deployer). Has special permissions (e.g., adding friends).
- `registeredFriends`: `mapping(address => bool)` whitelist that gates access to all user actions.
- `friendList`: `address[]` list of registered members (useful for frontends).
- `balances`: `mapping(address => uint256)` in‑contract ETH balances for each member.
- `debts`: `mapping(address => mapping(address => uint256))` nested mapping:
  - `debts[debtor][creditor] = amount` (e.g., Asha owes Ravi 1.5 ETH).

### Constructor
- Sets `owner = msg.sender`.
- Automatically registers the owner and pushes the owner’s address to `friendList`.

### Access Control (Modifiers)
- `onlyOwner`: restricts certain functions (like `addFriend`) to the owner.
- `onlyRegistered`: restricts core actions (deposit, record debt, pay, transfer, withdraw, check balance) to registered users.

## Core Functions

### 1) Add Friend (Owner‑only)
`addFriend(address _friend)`
- Validates `_friend` is non‑zero and not already registered.
- Adds `_friend` to `registeredFriends` and `friendList`.
- Purpose: keep the IOU group small, private, and secure.

### 2) Deposit ETH
`depositIntoWallet() payable`
- Requires `msg.value > 0`.
- Increases `balances[msg.sender]` by `msg.value`.
- Purpose: fund your in‑app balance to pay debts or transfer to friends.

### 3) Record Debt
`recordDebt(address _debtor, uint256 _amount)`
- Validates `_debtor` is non‑zero and registered; `_amount > 0`.
- Increases `debts[_debtor][msg.sender]` by `_amount`.
- Notes:
  - No ETH moves here—this only records that the debtor owes the creditor.

### 4) Pay From Wallet (Internal Settlement)
`payFromWallet(address _creditor, uint256 _amount)`
- Validates `_creditor` is non‑zero and registered; `_amount > 0`.
- Requires `debts[msg.sender][_creditor] >= _amount` and `balances[msg.sender] >= _amount`.
- Decreases payer’s balance; increases creditor’s balance; reduces recorded debt.
- Notes:
  - ETH remains inside the contract—this is an internal transfer of balances.

### 5) Transfer ETH (External Send via transfer)
`transferEther(address payable _to, uint256 _amount)`
- Validates `_to` is non‑zero and registered; requires sufficient balance.
- Decreases sender’s balance; sends ETH using `_to.transfer(_amount)`; then increases `_to`’s balance.
- Important:
  - `transfer` forwards only 2300 gas and auto‑reverts on failure.
  - Suitable for EOAs (wallets), but can fail with contracts that need more gas.

### 6) Transfer ETH (External Send via call)
`transferEtherViaCall(address payable _to, uint256 _amount)`
- Validates `_to` is non‑zero and registered; requires sufficient balance.
- Decreases sender’s balance; sends ETH via `(bool success, ) = _to.call{value: _amount}("")`; increases `_to`’s balance; requires `success`.
- Benefits:
  - No 2300 gas limit; works with smart contract wallets (e.g., Gnosis Safe).
- Caveat:
  - Always check `success` and design defensively against reentrancy in more advanced patterns.

### 7) Withdraw ETH
`withdraw(uint256 _amount)`
- Requires `balances[msg.sender] >= _amount`.
- Decreases user’s balance; sends ETH to the caller via `call`.
- Notes:
  - Uses `call` for broader compatibility; checks `success`.

### 8) Check Balance
`checkBalance() view returns (uint256)`
- Returns `balances[msg.sender]`.

## Typical Flows

### Group Setup
1. Owner deploys the contract (becomes `owner`, auto‑registered).
2. Owner calls `addFriend` for each participant.
3. Friends deposit ETH via `depositIntoWallet`.

### Recording and Settling Debts
- Record: Creditor calls `recordDebt(debtor, amount)` to log what the debtor owes.
- Settle internally: Debtor calls `payFromWallet(creditor, amount)` to move ETH within the contract and reduce the debt.

### Sending and Withdrawing ETH
- Send externally:
  - Use `transferEther` for simple wallet recipients (EOAs).
  - Use `transferEtherViaCall` for contract wallets needing more gas.
- Withdraw:
  - Call `withdraw(amount)` to move ETH from your in‑app balance back to your own wallet.

## Design Choices and Safety Notes
- Whitelist model: Keeps the IOU group private; all user actions are gated by `onlyRegistered`.
- Internal accounting: Moving balances inside the contract avoids repeated on‑chain transfers until needed.
- `transfer` vs `call`:
  - `transfer` auto‑reverts, has a 2300 gas stipend, and is simple but limited.
  - `call` is flexible (no gas limit) and compatible with contract wallets; must check `success` and consider reentrancy protections in more advanced versions.
- Defensive validation: Non‑zero addresses, registration checks, positive amounts, sufficient balances and debts.

## Possible Extensions (Future Work)
- Debt forgiveness: Allow a creditor to reduce or clear a debtor’s recorded debt.
- Group splits: Record shared expenses once, automatically split across members.
- Event logging: Emit events for deposits, debts recorded, settlements, transfers, withdrawals to aid indexing and UI updates.
- Reentrancy guards: Add OpenZeppelin’s `ReentrancyGuard` or checks‑effects‑interactions pattern for functions that call external addresses.
- Ownership transfer: Let the owner delegate or renounce ownership responsibly.
- Access reviews: Add functions to list members (`friendList`) for UIs; potentially pagination if the group grows.

## Quick Reference (Function Checklist)
- `addFriend(address _friend)` — Owner‑only; whitelist a friend.
- `depositIntoWallet()` — Payable; increase your in‑app balance.
- `recordDebt(address _debtor, uint256 _amount)` — Log debtor’s obligation to you.
- `payFromWallet(address _creditor, uint256 _amount)` — Settle debt internally.
- `transferEther(address payable _to, uint256 _amount)` — External send using `transfer`.
- `transferEtherViaCall(address payable _to, uint256 _amount)` — External send using `call`.
- `withdraw(uint256 _amount)` — Withdraw ETH back to your wallet.
- `checkBalance()` — View your in‑contract balance.
