# PollStation Contract Tutorial

## Core Data Structures

### Array: Candidate List
- Declaration: `string[] public candidateNames;`
- Purpose: store multiple candidate names in order.
- Public getter: Solidity auto-generates a read-only getter for public arrays.
- Common operation: `.push()` to add names dynamically.


### Mapping: Vote Counts
- Declaration: `mapping(string => uint256) private voteCount;`
- Purpose: track votes per candidate by name.
- Benefit: constant-time lookup without scanning the array.
  

## Complete Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PollStation {
    // List of candidate names
    string[] public candidateNames;

    // Fast existence check for candidates
    mapping(string => bool) private candidateExists;

    // Vote counts per candidate
    mapping(string => uint256) private voteCount;

    // Prevent duplicate votes: one address, one vote
    mapping(address => bool) public hasVoted;

    // Add a candidate (anyone can add in this simple version)
    function addCandidate(string calldata name) external {
        require(bytes(name).length > 0, "Empty name not allowed");
        require(!candidateExists[name], "Candidate already exists");

        candidateNames.push(name);
        candidateExists[name] = true;
        voteCount[name] = 0;
    }

    // Retrieve all candidate names
    function getCandidates() external view returns (string[] memory) {
        return candidateNames;
    }

    // Cast a vote for an existing candidate (one vote per address)
    function vote(string calldata name) external {
        require(candidateExists[name], "Candidate does not exist");
        require(!hasVoted[msg.sender], "Already voted");

        voteCount[name] += 1;
        hasVoted[msg.sender] = true;
    }

    // Get the vote count for a candidate
    function getVotes(string calldata name) external view returns (uint256) {
        require(candidateExists[name], "Candidate does not exist");
        return voteCount[name];
    }
}
```

## Function Explanations

- addCandidate
  - Input: `name` (string)
  - Behavior: ensures name is non-empty and unique; adds to the array; initializes votes to 0.

- getCandidates
  - Type: `view` (read-only)
  - Returns: array of all candidate names.

- vote
  - Input: `name` (string)
  - Behavior: ensures candidate exists and caller hasn’t voted; increments the candidate’s vote count; marks caller as voted.

- getVotes
  - Type: `view`
  - Returns: current vote count for the given candidate (reverts if the candidate doesn’t exist).


## Design Notes and Improvements

- Read-only calls: `view` functions (like `getCandidates`, `getVotes`) don’t modify state; frontends can call them off-chain without gas. On-chain calls still require a transaction and gas.
- Duplicate-vote protection: `hasVoted` ensures one vote per address in this simple model.
- Candidate validation: `candidateExists` prevents voting for non-existent candidates and avoids adding duplicates.
- String keys: using `string` is straightforward but can be gas-heavy at scale. For optimization, consider `bytes32` IDs (e.g., hashed names) or numeric IDs.
- Optional extensions:
  - Admin-only candidate management via access control (e.g., `Ownable` or custom admin).
  - Start/end