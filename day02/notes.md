# SaveMyName Contract — Store and Retrieve Name & Bio

## Overview

Traditional apps save user data in a database and update it as needed. Smart contracts are different: state lives permanently on the blockchain. That affects how we handle text and where data resides.

- State variables live on-chain (persistent).
- Function parameters and return values use temporary memory.
- Functions that modify state cost gas; pure reads are free (locally).

---

## Contract: SaveMyName.sol

Two state variables store a user’s profile:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SaveMyName {
    // State variables: permanently stored on-chain
    string private name;
    string private bio;

    // Store or update the profile
    function add(string memory _name, string memory _bio) public {
        name = _name;
        bio = _bio;
    }

    // Read-only: returns the stored name and bio
    function retrieve() public view returns (string memory, string memory) {
        return (name, bio);
    }

    // Compact version: save then return (costs gas)
    function saveAndRetrieve(string memory _name, string memory _bio)
        public
        returns (string memory, string memory)
    {
        name = _name;
        bio = _bio;
        return (name, bio);
    }
}
```

Notes:
- `string private name; string private bio;` are state variables (persist on-chain).
- `private` limits direct access; callers use functions instead.
- Parameters and return values use `memory` because they’re temporary during execution.
- `view` marks a read-only function; it doesn’t modify state.

---

## Key Concepts

### Strings need `memory` in functions
- In Solidity, dynamic types (like `string`) must specify data location in parameters and return values.
- Use `memory` for temporary data inside functions.


### Naming convention for clarity
- `_name` and `_bio` are common parameter styles to distinguish from state variables `name`, `bio`.
- It’s not required; you could use `newName`, `newBio`.

### Read vs. Write (Gas)
- Write (state change): costs gas (e.g., `add`, `saveAndRetrieve`).
- Read (`view`): free in local calls (e.g., `retrieve`). Note: reading via a transaction still incurs gas, but typical UI calls use `eth_call` which is free.

---

## API Reference

- `add(string _name, string _bio)` — public, state-changing
  - Stores or updates the profile.
  - Costs gas.

- `retrieve()` — public, `view`
  - Returns `(name, bio)`.
  - Free when called off-chain.

- `saveAndRetrieve(string _name, string _bio)` — public, state-changing
  - Saves values and immediately returns them.
  - Reduces round-trips but always costs gas.

---

## Usage Examples

Set profile:
```solidity
add("Alice", "Blockchain Developer");
```

Get profile:
```solidity
(string memory n, string memory b) = retrieve(); // n = "Alice", b = "Blockchain Developer"
```

One-shot save + get (gas cost applies):
```solidity
(string memory n, string memory b) = saveAndRetrieve("Bob", "Solidity Learner");
```

---

## Design Tradeoffs

- Two-function approach (`add` + `retrieve`):
  - Pros: Read is free; clear separation of responsibilities.
  - Cons: Two calls when you need to set and then read.

- Single-function approach (`saveAndRetrieve`):
  - Pros: Fewer calls; compact UX.
  - Cons: Always costs gas; not ideal when you only want to read.

Choose based on your UI flow and gas sensitivity.

---

## 

- Extend the profile:
  - Add fields like age (`uint8`), profession (`string`), avatar URL, etc.
- Use a struct for clarity:
  ```solidity
  struct Profile { string name; string bio; uint8 age; string profession; }
  ```
- Support multiple users:
  - Map `address => Profile` to store per-user data.
- Add access control:
  - Only the owner can update their profile.
- Events:
  - Emit `ProfileUpdated(address user, string name, string bio)` for off-chain indexing.

Minimal multi-user sketch:
```solidity
pragma solidity ^0.8.20;

contract Profiles {
    struct Profile { string name; string bio; }
    mapping(address => Profile) private profiles;

    event ProfileUpdated(address indexed user, string name, string bio);

    function add(string memory _name, string memory _bio) public {
        profiles[msg.sender] = Profile(_name, _bio);
        emit ProfileUpdated(msg.sender, _name, _bio);
    }

    function retrieve(address user) public view returns (string memory, string memory) {
        Profile storage p = profiles[user];
        return (p.name, p.bio);
    }
}
```


---

