# Yield Farming Contract: Simplified Guide

A practical, time-weighted reward system for staking ERC‑20 tokens with secure operations, fair accounting, and admin-managed reward funding.

## Overview

Yield farming lets users “plant” (stake) tokens to earn more tokens over time. This contract implements:
- Staking ERC‑20 tokens
- Second-by-second reward accrual
- Claiming rewards at any time
- Unstaking (with pending rewards preserved)
- Emergency withdraw (forfeit rewards, retrieve stake)
- Admin reward pool refills
- Reentrancy protection and safe decimal handling

It is a foundational pattern used across DeFi protocols (e.g., liquidity incentives, DAO treasuries, GameFi rewards, launchpads).

## Core Concepts

- Time-weighted rewards: Users earn proportional to staked amount × time.
- No minting: Rewards must be pre-funded by admin into the contract.
- Decimals-aware math: Rewards are normalized using the staking token’s decimals.
- Safety first: Sensitive functions use reentrancy protection; ETH is unsupported (ERC‑20 only).

## Contract Interface (Key Elements)

- Tokens
  - stakingToken: ERC‑20 users deposit
  - rewardToken: ERC‑20 paid out as rewards
- Parameters
  - rewardRatePerSecond: rewards emitted per second (scaled by decimals)
  - owner: admin authorized to refill rewards
  - stakingTokenDecimals: cached decimals for normalization
- Per-user data (StakerInfo)
  - stakedAmount
  - rewardDebt (unclaimed rewards accrued so far)
  - lastUpdate (timestamp for reward accrual)

### Events

- Staked(user, amount)
- Unstaked(user, amount)
- RewardClaimed(user, amount)
- EmergencyWithdraw(user, amount)
- RewardRefilled(owner, amount)

## Functions and Flow

### 1) stake(amount)
- Require amount > 0
- Update user rewards to “lock in” what was earned so far
- Transfer `amount` of stakingToken from user to contract
- Increase user’s `stakedAmount`
- Emit Staked

Effect: User starts (or increases) farming immediately with accurate reward tracking.

### 2) unstake(amount)
- Require amount > 0 and <= stakedAmount
- Update user rewards first (they keep pending rewards)
- Decrease `stakedAmount`
- Transfer tokens back to user
- Emit Unstaked

Effect: Smooth exit of principal while preserving earned rewards.

### 3) claimRewards()
- Update user rewards
- Read `rewardDebt` and require > 0
- Ensure contract holds enough `rewardToken`
- Reset `rewardDebt` to 0 and transfer rewards
- Emit RewardClaimed

Effect: Harvest accumulated rewards without affecting principal.

### 4) emergencyWithdraw()
- Require user has staked > 0
- Reset `stakedAmount`, `rewardDebt`
- Set `lastUpdate` to now
- Transfer staked tokens back
- Emit EmergencyWithdraw

Effect: Immediate principal retrieval; forfeits any pending rewards.

### 5) refillRewards(amount) [onlyOwner]
- Transfer reward tokens from owner to contract
- Emit RewardRefilled

Effect: Top up the reward pool without redeploying; keeps farming sustainable.

### 6) pendingRewards(user) (view)
- Base on stored `rewardDebt`
- If user has stake, add current accrual since `lastUpdate`:
  - pending += (timeDiff × rewardRatePerSecond × stakedAmount) / (10^stakingTokenDecimals)
- Return total pending

Effect: Live view of claimable rewards without state changes.

### 7) getStakingTokenDecimals() (view)
- Returns cached decimals for stakingToken

Effect: Frontends can display balances and rewards correctly.

## Reward Calculation Details

- Rewards accrue linearly per second:
  pending = sum over intervals of
  (seconds_elapsed × rewardRatePerSecond × stakedAmount) / 10^stakingTokenDecimals
- `updateRewards(user)`:
  - If `stakedAmount > 0`, compute pending since `lastUpdate` and add to `rewardDebt`
  - Set `lastUpdate = block.timestamp`
- Decimal handling ensures correctness across tokens (e.g., 6 decimals for USDC, 18 for ETH-like tokens).

## Security Considerations

- ReentrancyGuard on stake, unstake, claimRewards, emergencyWithdraw
- No ETH acceptance; only ERC‑20 transfers
- Safe handling of decimals; math normalized using token decimals
- Admin refills do not mint; use transferFrom with prior approval

## Admin and User Responsibilities

- Admin must pre-fund rewards via `refillRewards` (after approving the contract to transfer reward tokens).
- Users must approve the staking contract to move their staking tokens before calling `stake`.

## Example Setup (Remix)

1) Deploy two ERC‑20 tokens (e.g., StakeToken STK and RewardToken RWD).
2) Deploy YieldFarming with:
   - stakingToken = STK address
   - rewardToken = RWD address
   - rewardRatePerSecond = suitable value (e.g., 1e15 for 0.001 RWD/sec at 18 decimals)
3) Approvals:
   - User approves stakingToken spend by YieldFarming
   - Owner approves rewardToken spend by YieldFarming
4) Fund rewards:
   - Owner calls `refillRewards(amount)`
5) Stake:
   - User calls `stake(amount)`
6) Monitor:
   - Call `pendingRewards(user)`
7) Harvest:
   - Call `claimRewards()`
8) Exit:
   - Call `unstake(amount)` or `emergencyWithdraw()`

## Notes on Consistency (Reconciled)

- Rewards accrue “second-by-second” (not per block) in both versions.
- Claim resets `rewardDebt` to zero after transfer.
- Unstake calculates and preserves pending rewards before reducing stake.
- Emergency withdraw forfeits pending rewards by resetting `rewardDebt`.
- Decimals handling uses staking token’s decimals; default to 18 if unavailable.
- Admin refills use transferFrom; no minting occurs within the contract.

## Practical Tips

- Choose `rewardRatePerSecond` aligned with total reward pool and desired program duration.
- Frontends should poll `pendingRewards` to display live earnings.
- Consider multi-sig ownership for safer admin operations in production.
- Index events in analytics for user histories and program health dashboards.