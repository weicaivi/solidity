# SafeDeposit: A Modular Vault System

This guide explains a modular vault (“deposit box”) system in Solidity that lets users store on-chain secrets with different behaviors. It combines shared standards (interfaces), reusable logic (abstract contracts), and concrete vault types, all managed by a central controller.

## Overview

- Interface (IDepositBox): Defines the standard every vault must implement.
- Abstract base (BaseDepositBox): Implements shared storage, ownership, events, and access control.
- Concrete vaults:
  - BasicDepositBox: Minimal, standard behavior.
  - PremiumDepositBox: Adds metadata support.
  - TimeLockedDepositBox: Restricts secret retrieval until a future time.
- VaultManager: A controller to create and manage users’ vaults, names, and ownership changes.

Why this matters:
- Predictable interactions across different vault types
- Clean separation of concerns
- Scalable, maintainable architecture using interfaces, inheritance, and composition—similar to production systems in widely used libraries and protocols.

---

## 1) The Interface: IDepositBox.sol

Purpose: Enforce a common API every vault must support.

Required functions:
- getOwner(): address of the current owner
- transferOwnership(address): change the owner
- storeSecret(string): save a secret
- getSecret(): retrieve the secret
- getBoxType(): identify vault type (“Basic”, “Premium”, “TimeLocked”)
- getDepositTime(): timestamp of vault creation

Contract snippet (conceptual):
- External view/pure functions for reads and type identification
- External mutating functions for storing secrets and transferring ownership

Design notes:
- Interfaces contain only function signatures—no storage, modifiers, or implementation.
- Enables tooling (e.g., managers/dashboards) to treat all vaults uniformly.

---

## 2) Abstract Base: BaseDepositBox.sol

Purpose: Provide shared logic and storage while leaving type-specific details (getBoxType) to child contracts.

Core storage:
- owner: address
- secret: string
- depositTime: uint256 (block timestamp at deployment)

Events:
- OwnershipTransferred(previousOwner, newOwner)
- SecretStored(owner)

Access control:
- modifier onlyOwner: restricts sensitive functions to the current owner

Key behaviors:
- Constructor: sets owner = msg.sender, depositTime = block.timestamp
- getOwner(): returns owner
- transferOwnership(newOwner): requires non-zero address; emits OwnershipTransferred; updates owner
- storeSecret(_secret): owner-only; saves and emits SecretStored
- getSecret(): owner-only read
- getDepositTime(): read-only; useful for time-based logic

Implementation tips:
- Keep storage variables private; expose reads via getters
- Use consistent error strings and modifiers to prevent unauthorized access

Note: As an abstract contract, BaseDepositBox intentionally does not implement getBoxType(); child contracts must provide it.

---

## 3) Concrete Vaults

### a) BasicDepositBox.sol
Minimal vault implementing getBoxType() and inheriting all base behaviors.

- getBoxType(): returns "Basic"
- Inherits:
  - Ownership management
  - Secret storage/retrieval
  - Deposit time tracking
  - Events and onlyOwner

Use case: Default vault for straightforward secret storage.

### b) PremiumDepositBox.sol
Extends the base with metadata support.

Storage and events:
- metadata: string (private)
- MetadataUpdated(owner)

Functions:
- getBoxType(): "Premium"
- setMetadata(_metadata): owner-only; update and emit MetadataUpdated
- getMetadata(): owner-only; read metadata

Use case: Attach contextual information or labels (e.g., “Backup keys”, “Access after retirement”).

### c) TimeLockedDepositBox.sol
Adds time-lock mechanics to delay secret retrieval.

Storage:
- unlockTime: uint256 (computed at deployment)

Constructor:
- Accepts lockDuration (seconds) and sets unlockTime = block.timestamp + lockDuration

Modifier:
- timeUnlocked: requires block.timestamp >= unlockTime

Functions:
- getBoxType(): "TimeLocked"
- getSecret(): owner-only, timeUnlocked; returns base secret via super.getSecret()
- getUnlockTime(): view unlock timestamp
- getRemainingLockTime(): view countdown; returns 0 when unlocked, otherwise unlockTime - block.timestamp

Use case: Time capsules, delayed reveals, scheduled unlocks.

---

## 4) Controller: VaultManager.sol

Purpose: A single point of interaction to create, name, and manage vaults for users.

Storage:
- userDepositBoxes: mapping(address => address[]) tracks vault addresses per user
- boxNames: mapping(address => string) records custom names per vault address

Events:
- BoxCreated(owner, boxAddress, boxType)
- BoxNamed(boxAddress, name)

Creation functions:
- createBasicBox(): deploy BasicDepositBox, store under user, emit BoxCreated
- createPremiumBox(): deploy PremiumDepositBox, store under user, emit BoxCreated
- createTimeLockedBox(lockDuration): deploy TimeLockedDepositBox with lockDuration, store under user, emit BoxCreated

Management functions:
- nameBox(boxAddress, name): require caller is box owner; set name; emit BoxNamed
- storeSecret(boxAddress, secret): require caller is box owner; delegate to box.storeSecret(secret)
- transferBoxOwnership(boxAddress, newOwner):
  - require caller is box owner
  - delegate to box.transferOwnership(newOwner)
  - update userDepositBoxes by removing from sender and adding to newOwner (swap-and-pop removal)

Query functions:
- getUserBoxes(user): returns array of vault addresses owned by user
- getBoxName(boxAddress): returns name (empty string if unset)
- getBoxInfo(boxAddress): returns (boxType, owner, depositTime, name)

Design notes:
- Operates via IDepositBox interface—no need to know concrete type
- Keeps frontend-friendly metadata alongside on-chain vault state

---

## 5) Practical Guidance and Consistency Checks

- Box type strings: Prefer "TimeLocked" (without space) for consistency across code and UI.
- Error messages: Standardize to a single phrasing (e.g., "Not the box owner") to match BaseDepositBox and tutorials.
- Visibility and mutability:
  - Use external + view/pure for read utilities, external for mutations
  - Use calldata for string parameters to save gas
- Array removal in transfer:
  - Ensure you check for a matching element before swap-and-pop
  - Current pattern swaps the found item with the last and pops; break after removal
- Access control:
  - Secret reads and writes should be owner-only
  - Deposit time read can be public or external view; typically not restricted
- Event coverage:
  - OwnershipTransferred, SecretStored, MetadataUpdated, BoxCreated, BoxNamed
  - Emit events on state changes to support indexing and UX

---

## 6) Example Flows

- Create and store:
  1) User calls createBasicBox() → gets box address
  2) User calls storeSecret(boxAddress, "hello")
  3) User calls getSecret() on the box to read, restricted by onlyOwner

- Premium metadata:
  1) createPremiumBox()
  2) setMetadata("Backup keys for wallet X")
  3) getMetadata() (owner-only)

- Time-locked access:
  1) createTimeLockedBox(3600) // lock 1 hour
  2) storeSecret(...)
  3) getRemainingLockTime() for UI countdown
  4) After unlockTime, getSecret() succeeds

- Ownership transfer:
  1) transferBoxOwnership(boxAddress, newOwner)
  2) VaultManager updates userDepositBoxes arrays accordingly

---

## 7) Files and Roles

- IDepositBox.sol: Interface (API contract)
- BaseDepositBox.sol: Abstract base (shared logic and storage)
- BasicDepositBox.sol: Minimal concrete type
- PremiumDepositBox.sol: Concrete type with owner-only metadata
- TimeLockedDepositBox.sol: Concrete type with unlock schedule
- VaultManager.sol: Controller for creation, naming, secret storage delegation, and ownership transfers

---


## 8) Q&A

`external` vs `public`

- In the interface, functions are typically declared external to describe how other contracts will call them. Interfaces define how callers interact from the outside. Declaring functions external is conventional and ensures they’re callable from other contracts and transactions. Interfaces can only have function signatures (no bodies), so visibility is about the external ABI.

- In the implementation, you can use public (or external). external only creates the external entry point and can be slightly more gas‑efficient for certain argument types. public is a superset: it creates both an external entry point and an internal callable function. Public functions generate:

    - an external ABI function (so other contracts/EOAs can call it), and
    - an internal function that the contract (and its children) can call without an external call. That internal call path can be cheaper than calling an external function via this.getOwner().
    - Call sites inside the contract:
      - public: you can call getOwner() directly as an internal call.
      - external: you cannot call it directly; you must use this.getOwner(), which performs an external call to yourself (more gas and reentrancy considerations).
    - Gas:
      - For complex calldata types, external can be a bit cheaper when called from outside.
      - For internal use, public is cheaper because it avoids the external call.
    - ABI compatibility:
      - A public function satisfies an external interface requirement. The external ABI exists for a public function, so implementing an external interface function with a public function is valid.

`pure` vs `view`
- Pure: The function guarantees it doesn’t read or write any state. No storage reads, no globals like block.timestamp or msg.sender, no state variables. It can only use its inputs and local computations. Example: a math utility.

- View: The function guarantees it doesn’t modify state but may read it. It can access state variables, mappings, and some globals. Example: getters.
- Both restrict writes; only pure additionally restricts reads.
- Use pure for standalone computations; use view for getters.

`virtual`

- Declares that a function in a base contract can be overridden by derived contracts.

- Often paired with override in the child.

deployer, owner, `address(this)`, `msg.sender`

    Deployer creates the contract; owner is whoever the contract records as having authority. address(this) is the contract’s own address; msg.sender is the current caller.
    
    Bottom line: Deployer is “who created the contract” at deployment time; owner is “who the contract currently trusts.” msg.sender is “who is calling right now,” and address(this) is “the contract itself.”

- Deployer: The account/contract that sends the deployment transaction. In the constructor, `msg.sender` equals the deployer. Many contracts set `owner = msg.sender` in the constructor, so the deployer becomes the initial owner.

- Owner: A stored address that represents who has privileged control (e.g., onlyOwner functions). Unlike the deployer, owner can change later via transferOwnership. It may be an EOA or another contract.

- `msg.sender`: The immediate caller of the current function. It’s:
  - The deployer inside the constructor.
  - The EOA or contract making the call during normal execution.
  - Important nuance: in meta-transactions or factory patterns, `msg.sender` might be a relayer or factory, not the end user.

- `address(this)`: The contract’s own address. Use it to:
  - Pass your contract address to other contracts or approvals.
  - Receive Ether or tokens to the contract.
  - Identify “who” holds assets (the contract itself), not “who” called a function.

  How they relate in common patterns:
  - Setting ownership: constructor sets `owner = msg.sender` (the deployer at deployment). Later, owner can differ from the deployer after transferOwnership.

  - Access control: onlyOwner typically checks `require(msg.sender == owner, …)`. Don’t compare owner to `address(this)`; `address(this)` is the vault’s address, not the caller.

  - Factories: If a Factory deploys your vault, the deployer is the Factory (`msg.sender` in constructor). If you want the end user to be owner, pass their address into the constructor or immediately call transferOwnership to the user.

  - delegatecall: `msg.sender` is preserved from the original caller, while` address(this)` becomes the address of the callee contract. This distinction matters in proxy patterns.

