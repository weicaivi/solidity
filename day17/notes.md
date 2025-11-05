# Upgradeable Contracts: Proxy + delegatecall

Smart contracts are immutable once deployed unless you design them to be upgradeable. Upgradeability lets you fix bugs, add features, and improve efficiency without migrating user data or redeploying the storage contract.

## Key Idea: Separate Storage from Logic

- Proxy contract: holds all state (storage) and forwards calls.
- Logic contracts (implementations): hold business logic and can be replaced over time.
- delegatecall: executes logic contract code in the storage context of the proxy, preserving data.

When you need new behavior, upgrade the proxy’s pointer to a new logic contract. The data stays intact.

## Upgradeable Subscription Manager

A modular subscription system suitable for SaaS apps or dApps:

- Shared storage layout
- Proxy contract that delegates calls
- Logic V1: basic plans, subscribe, isActive
- Logic V2: adds pause/resume

## 1) Shared Storage Layout: SubscriptionStorageLayout.sol

Defines the memory layout used by both proxy and logic contracts. Matching layout is critical for delegatecall correctness.

- uint8 for planId saves gas.
- Expiry uses uint256 to store large timestamps.
- Public mappings enable quick reads (frontends, other contracts).

## 2) Proxy Contract: SubscriptionStorage.sol

Owns the data and forwards calls to the current logic via delegatecall. Upgrades simply replace the logic address.

- The proxy’s storage layout matches the logic’s expectation (inheritance).
  - In Solidity, each state variable has a fixed storage slot number and packing rules derived from its declaration order and types. When the proxy and logic contracts both inherit the exact same layout contract, they compile to the same slot mapping. That means when the logic executes via delegatecall and does SLOAD/SSTORE, it hits the proxy’s slots with the same offsets it expects.
  - What could break it
    - Changing variable order in a new logic version: If V2 introduced a new variable before owner, every subsequent variable’s slot shifts. Reads/writes then go to the wrong positions (e.g., what the logic thinks is owner might now read your new variable).
    - Changing a type or struct field order: Reordering fields in Subscription (e.g., bool paused placed before uint256 expiry) changes packing and slot usage. Logic compiled against the old layout would read garbage or overwrite wrong data.
    - Adding variables in the middle instead of at the end: New variables must be appended at the end of the layout, not inserted between existing ones, or the slot numbering/padding changes.
    - Not inheriting the layout at all in a logic contract: If a logic contract defines its own state variables, the compiler assigns slots relative to that contract’s definition, which will not match the proxy’s actual storage.
    - Typical safe pattern is:
      - Put all storage in a single layout contract.
      - Never reorder or remove existing fields.
      - Only append new fields at the end.


- delegatecall executes logic while reading/writing the proxy’s storage.
  - delegatecall swaps in the callee’s code but keeps the caller’s execution context:
    - Storage: SLOAD/SSTORE operate on the caller (proxy) storage.
    - Address context: address(this) remains the proxy’s address.
    - msg.sender: remains the original external caller.
    - msg.value: is preserved and visible to the logic code if the proxy forwards payable calls.
    - Balance/ETH transfers: if the logic executes transfers, they come from the proxy’s balance.
    - selfdestruct: if the logic calls selfdestruct, it will selfdestruct the proxy, not the logic contract.
  -  proxy’s fallback illustrates the raw mechanism:
     -  It copies calldata, calls delegatecall(gas(), impl, …), and returns the result. 
     -  The logic code runs, but every read/write (including mappings and structs) goes to the proxy’s storage.
  -  Storage math examples under delegatecall
     -  Simple variables: logicContract lives at slot 0; owner at slot 1. SSTORE to slot 1 from logic will update the proxy’s owner.
     - Mappings:
       - mappings use slot hashing: slot = keccak256(abi.encode(key, baseSlot)).
       - subscriptions maps an address to Subscription. When logic writes subscriptions[user].expiry, it computes the same keccak slot and writes to the proxy’s mapping storage.
     - Struct packing: Fields inside a struct occupy contiguous slots based on types and order. delegatecall respects the compiled offsets, so a write to s.paused flips the proxy’s paused bit if the layout matches.




- upgradeTo switches to new logic without touching data.

## 3) Logic V1: SubscriptionLogicV1.sol

Implements core subscription behavior.
- addPlan sets price and duration per planId.
- subscribe extends remaining time or resets expiry if expired.
- isActive returns true if not expired and not paused.

## 4) Logic V2: SubscriptionLogicV2.sol

Extends V1 with pause/resume controls (admin or future self-service).

- Pause does not change expiry; time keeps ticking while access is blocked.
- You can later add access control (e.g., onlyOwner or roles) to governance-sensitive functions.

## Why This Architecture Is Powerful

- No data migration: storage stays in the proxy.
- No downtime: switch logic instantly with upgradeTo.
- Extensible: add features (pause, roles, pricing changes) in new logic versions.
- Gas-aware: compact types (uint8) where appropriate; minimal proxy logic.

## Next Hardening Steps (Recommended)

- Add access control (Ownable or RBAC) to admin functions (addPlan, pauseAccount, upgradeTo).
- Emit events (PlanAdded, Subscribed, Paused, Resumed, Upgraded) for indexing/UX.
- Consider UUPS or Transparent Proxy patterns from OpenZeppelin for standardized upgrade safety.
- Add reentrancy guards if integrating with external calls or token transfers.
- Validate payments precisely and handle refunds/overpayment if required.