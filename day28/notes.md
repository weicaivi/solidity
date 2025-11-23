# Decentralized Governance DAO: Simplified Guide and Reference

A decentralized governance system turns community decisions into on-chain actions—proposals are created, votes are cast with token-weighted power, results are validated against quorum, a timelock provides a safety window, and approved actions are executed automatically by contracts. This document merges the English tutorial’s narrative with the Chinese version’s structured details to give you a concise, technically accurate reference.

## What Is a DAO?

A DAO (Decentralized Autonomous Organization) is governed by smart contracts, not managers. Token holders propose, vote, and execute decisions transparently on-chain. Real projects like Uniswap and Compound use similar models: token-weighted voting, quorum requirements, and time-delayed execution.

## System Goals

- Transparent, on-chain decision-making
- Token‑weighted voting (1 token = 1 vote)
- Minimum participation (quorum) to validate proposals
- Timelock delay before execution for safety and accountability
- Automatic execution of approved proposals
- Anti-spam safeguards via proposal deposits

## Roles and User Flows

- Admin
  - Deploy the contract
  - Configure governance parameters: voting duration, timelock, quorum percentage, proposal deposit
  - Adjust parameters as needed (no direct influence on vote outcomes)

- Proposer
  - Holds enough governance tokens to pay a proposal deposit
  - Submits a proposal (description + execution targets + calldata)
  - Deposit is refunded if the proposal passes and executes

- Voter
  - Must hold governance tokens
  - Casts a vote (for/against) during the voting window
  - Voting power equals current token balance (token-weighted)

## Core Mechanics

- Voting Power
  - Weight = governanceToken.balanceOf(voter)
  - One address can vote once per proposal (hasVoted mapping)
- Quorum
  - RequiredVotes = totalSupply * quorumPercentage / 100
  - Valid only if totalVotes ≥ RequiredVotes and forVotes > againstVotes
- Timelock
  - After a proposal passes, timelock starts
  - Execution only after timelockEnd has elapsed
- Deposits
  - Collected when creating proposals
  - Refunded upon successful execution
  - Not refunded for failed proposals

## Contract Overview (Key Interfaces and Structures)

- Imports
  - IERC20 (governance token)
  - ReentrancyGuard (protects external calls during execution)

- State
  - governanceToken: IERC20
  - nextProposalId: uint256
  - votingDuration: uint256 (seconds)
  - timelockDuration: uint256 (seconds)
  - admin: address
  - quorumPercentage: uint256 (0–100)
  - proposalDepositAmount: uint256
  - proposals: mapping(uint256 ⇒ Proposal)
  - hasVoted: mapping(uint256 ⇒ mapping(address ⇒ bool))

- Proposal struct
  - proposer: address
  - description: string
  - forVotes: uint256
  - againstVotes: uint256
  - startTime: uint256
  - endTime: uint256
  - executed: bool
  - canceled: bool
  - timelockEnd: uint256
  - Optional execution payloads (targets + calldatas), if using action calls on other contracts

- Events
  - ProposalCreated(proposalId, proposer, description)
  - Voted(proposalId, voter, support, weight)
  - ProposalTimelockStarted(proposalId)
  - ProposalExecuted(proposalId)
  - QuorumNotMet(proposalId)

- Modifiers
  - onlyAdmin
  - nonReentrant (from ReentrancyGuard)

## Governance Lifecycle

1. Create Proposal
   - Proposer pays deposit (transferFrom)
   - Proposal is stored with start/end times
   - Emit ProposalCreated

2. Vote
   - Allowed only during [startTime, endTime]
   - Token-weighted votes added to forVotes/againstVotes
   - Emit Voted

3. Finalize
   - After endTime
   - Check quorum and majority (for > against)
   - If passed: set timelockEnd = now + timelockDuration, emit ProposalTimelockStarted
   - Else: mark canceled or executed (failed), emit QuorumNotMet if applicable

4. Execute
   - After timelockEnd and not previously executed/canceled
   - Mark executed early (reentrancy protection)
   - Optionally loop through targets and calldatas to perform on-chain actions
   - Refund deposit to proposer
   - Emit ProposalExecuted

## Admin Functions

- setQuorumPercentage(uint256 newQuorum)
  - 0 < newQuorum ≤ 100

- setProposalDepositAmount(uint256 newAmount)

- setTimelockDuration(uint256 newDuration)

## Reference Implementation Notes

The English tutorial focuses on narrative and a single-file DAO contract. The Chinese version adds a clear product spec, role flows, data tables, and explains safeguards like quorum and timelock thoroughly. This merged guide:

- Uses token-weighted voting (ERC-20 balance-based) for simplicity and clarity
- Includes proposal deposits (spam resistance) and refunds upon successful execution
- Enforces quorum plus majority for validity
- Applies a timelock between finalization and execution
- Protects external calls with ReentrancyGuard

If you choose to include action execution:
- Store executionTargets (address[]) and executionData (bytes[])
- On executeProposal, iterate and call each target with its calldata; revert on failure to maintain atomicity

## Quick Start (Remix)

1. Deploy GovernanceToken (ERC-20)
   - Mint a fixed supply to deployer

2. Deploy DecentralizedGovernance
   - Pass governanceToken address, votingDuration (e.g., 3600), timelockDuration (e.g., 1800)
   - Configure quorumPercentage (e.g., 20) and proposalDepositAmount (e.g., 100)

3. Approve deposit
   - governanceToken.approve(governanceContract, proposalDepositAmount)

4. Create a proposal
   - createProposal(description, targets, calldatas)
   - Store any contract actions to perform if it passes

5. Vote
   - vote(proposalId, true/false) during the window

6. Finalize
   - finalizeProposal(proposalId) after endTime
   - If passed, a timelock starts

7. Execute
   - executeProposal(proposalId) after timelock ends
   - Deposit refunded to proposer if successful

## Extensions (Next Steps)

- Delegated voting (vote power via ERC20Votes or custom delegate mapping)
- Proposal categories with different quorum/thresholds
- Multi-sig admin to decentralize parameter control
- Treasury management (fund transfers with safeguards)
- Emergency pause (circuit breaker for proposals/execution)
- Snapshot-based voting (prevent balance changes from affecting ongoing votes)

## Security Considerations

- Reentrancy protection on execute (set executed before external calls)
- Validate targets and calldatas lengths on proposal creation
- Use reasonable timelock to allow community response
- Consider snapshot voting (ERC20Votes) to prevent last-minute balance manipulation
- Consider rate-limiting or higher deposits to mitigate spam
- Emit events for transparency on all state changes