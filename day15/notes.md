# Gas-Efficient Voting

Lean patterns for building a voting contract that stays functional, scalable, and affordable on-chain.

## Why Gas Optimization Matters
Voting contracts often receive high traffic. Without careful design, simple actions (like casting a vote) can become too expensive. This guide reworks a standard voting contract with gas efficiency in mind—preserving functionality while cutting costs.

## What Stays the Same
- Users can create proposals
- Users can vote
- We track who voted and how many votes each proposal has
- Proposals can be executed after voting ends
- Events are emitted for transparency

## Key Optimizations at a Glance
- Prefer fixed-size types (bytes32, uint8/uint32) over dynamic ones (string, uint256 everywhere)
- Use mappings for O(1) access instead of dynamic arrays
- Pack voter history into a single uint256 bitmap per address
- Minimize storage writes and keep events small
- Build structs in memory, then write once to storage

---

## Baseline (Unoptimized) Pattern
Common beginner choices that increase gas:
- `string` for names (dynamic, costly) instead of `bytes32`
- Dynamic arrays for proposals
- Nested mappings for vote tracking: `mapping(address => mapping(uint => bool))`
- Multiple storage writes per interaction

---

## Optimized Contract Overview

- `proposalCount` is `uint8` (support up to 255 proposals); smaller types save gas.
- `Proposal` struct uses compact fields to reduce storage slots:
  - `bytes32 name`
  - `uint32 voteCount`
  - `uint32 startTime`
  - `uint32 endTime`
  - `bool executed`
- `proposals` stored in `mapping(uint8 => Proposal)` for direct access.
- `voterRegistry` packs votes per address: each bit in a `uint256` indicates whether the user voted on a given proposal ID.
- Optional `proposalVoterCount` tracks unique voters per proposal for analytics/UI.

---

## Storage Layout

- `uint8 public proposalCount`  
  We likely won’t exceed 255 proposals; `uint256` wastes 31 bytes here.

- `struct Proposal { bytes32 name; uint32 voteCount; uint32 startTime; uint32 endTime; bool executed; }`  
  Carefully chosen types support struct packing, reducing the number of storage slots.

- `mapping(uint8 => Proposal) public proposals`  
  Mapping avoids array growth costs and bounds checks on push.

- `mapping(address => uint256) private voterRegistry`  
  Bitmap approach: bit i represents whether an address voted on proposal i (supports up to 256 proposals per address).

- `mapping(uint8 => uint32) public proposalVoterCount` (optional)  
  Tracks unique voters; useful for UI/analytics with minimal overhead.

---

## Events
- `ProposalCreated(uint8 indexed proposalId, bytes32 name)`
- `Voted(address indexed voter, uint8 indexed proposalId)`
- `ProposalExecuted(uint8 indexed proposalId)`

Keep events compact; indexed fields improve log filtering.

---

## Core Functions

### 1) Create Proposal
- Validate duration > 0
- Use `proposalCount` as the ID; increment with `uint8`
- Build `Proposal` in memory, assign once to storage
- Emit `ProposalCreated`

### 2) Vote
- Validate `proposalId` range
- Check voting window using `uint32(block.timestamp)`
- Use a bitmask to detect whether the voter already voted:
  - `mask = 1 << proposalId`
  - `(voterRegistry[msg.sender] & mask) == 0` means not voted
- Record vote by setting the bit: `voterRegistry[msg.sender] |= mask`
- Increment `proposal.voteCount` and `proposalVoterCount[proposalId]`
- Emit `Voted`

### 3) Execute Proposal
- Validate `proposalId`
- Ensure the voting window has ended
- Ensure not already executed
- Set `executed = true`
- Emit `ProposalExecuted`
- In real-world use, add execution logic (e.g., token transfer, DAO config change)

### 4) Read: Has Voted
- Return whether a voter’s bit is set for `proposalId` using the bitmap

### 5) Read: Get Proposal
- Validate `proposalId`
- Return all fields plus an `active` flag (whether voting is currently open)

---

## Design Notes and Rationale

- bytes32 vs string: `bytes32` is fixed-size and cheaper; convert human-readable names off-chain.
- uint8/uint32 vs uint256: Use the smallest type that fits your domain to improve packing and reduce gas.
- Struct packing: Solidity stores data in 32-byte slots; tight packing minimizes slots and gas.
- Mappings over arrays: Direct O(1) access without array resizing. Combined with a counter ID is simpler and cheaper.
- Bitmap for votes: One storage slot per voter, bit operations for reads/writes are cheap and avoid nested mappings.
- Events: Keep arguments minimal; use `indexed` for filterability.
- View functions: Off-chain calls are free (no gas) and should return exactly the data the UI needs.

---

## Practical Limits & Considerations

- Proposal cap: `uint8` supports up to 255 proposals; if you need more, move to `uint16` and consider a different bitmap strategy (e.g., paging per voter).
- Timestamp range: `uint32` timestamps cover dates until ~year 2106; adequate for most voting windows.
- Name representation: If you require long, human-readable names on-chain, store a `bytes32` key or hash and resolve off-chain (IPFS/metadata) to avoid gas-heavy strings.
- Reentrancy: This pattern does not perform external calls in core mutations; if execution logic adds them, guard with checks/effects/interactions and consider reentrancy protection.
- Access control: Anyone can execute after the window ends; if you need role-based execution, add access modifiers or DAO governance hooks.

---

## Checklist: Optimize Your Own Contracts
- Are you using dynamic types where fixed-size types suffice?
- Can you pack related data into fewer storage slots?
- Can you replace arrays with mappings + counters?
- Can you compress per-user flags/states into bitmaps?
- Are your events minimal and well-indexed?
- Are you building complex structs in memory before a single storage write?

---

## Takeaway
Writing Solidity is one thing. Writing gas-efficient Solidity is how you scale. Think in bits, bytes, and storage slots, and choose types and data structures that minimize writes. Keep the UX the same—make the gas cheaper.