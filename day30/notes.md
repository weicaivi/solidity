# Mini DEX

A minimal, from-scratch decentralized exchange composed of two smart contracts:

- MiniDexPair.sol — the pool engine: swaps, reserves, LP accounting, fees
- MiniDexFactory.sol — the pool registry/creator: deploy, track, and retrieve pairs

This is on-chain backend logic only (no frontend). It demonstrates automated market makers (AMMs), liquidity provisioning, and proportional LP ownership with a constant product curve.

---

## 1) MiniDexPair.sol — The Pool

### Purpose
Holds two ERC-20 tokens (TokenA, TokenB), enables:
- Add/remove liquidity in proportion to pool reserves
- Swap between TokenA and TokenB via the constant product formula x * y = k
- Track reserves, total LP supply, individual LP balances, and apply a 0.3% fee

### Key Imports
- IERC20 (OpenZeppelin): ERC-20 interface for transferFrom, transfer, balanceOf
- ReentrancyGuard (OpenZeppelin): protects addLiquidity, removeLiquidity, swap from reentrancy

### State
- tokenA, tokenB (immutable addresses): fixed at construction
- reserveA, reserveB (uint256): cached balances for pricing math
- totalLPSupply (uint256): total LP “shares” (internal accounting, not an ERC-20)
- lpBalances[address] (uint256): per-user LP shares

### Events
- LiquidityAdded(provider, amountA, amountB, lpMinted)
- LiquidityRemoved(provider, amountA, amountB, lpBurned)
- Swapped(user, inputToken, inputAmount, outputToken, outputAmount)

### Core Mechanics

- addLiquidity(amountA, amountB)
  - Transfers both tokens into the pool
  - If first deposit: lpMinted = sqrt(amountA * amountB) (geometric mean)
  - Else: lpMinted = min(amountA * totalLP / reserveA, amountB * totalLP / reserveB)
  - Updates lpBalances and totalLPSupply; syncs reserves

- removeLiquidity(lpAmount)
  - Pro-rata redemption:
    - amountA = lpAmount * reserveA / totalLP
    - amountB = lpAmount * reserveB / totalLP
  - Burns LP shares, transfers tokens out, syncs reserves

- getAmountOut(inputAmount, inputToken) view
  - 0.3% fee modeled as 997/1000
  - Directional reserves: (inputReserve, outputReserve)
  - Formula:
    - inputWithFee = inputAmount * 997
    - numerator = inputWithFee * outputReserve
    - denominator = inputReserve * 1000 + inputWithFee
    - output = numerator / denominator

- swap(inputAmount, inputToken)
  - Validates, computes output via getAmountOut
  - Transfers in input token, transfers out output token
  - Syncs reserves, emits Swapped

- Reserve synchronization
  - _updateReserves() reads on-chain balances to keep pricing accurate and prevent stale-state exploits

### Utility Helpers
- sqrt(y): Babylonian method for integer sqrt used in initial LP mint
- min(a, b): proportional minting respects pool ratio; prevents gaming by over-supplying one side

### View Functions
- getReserves() → (reserveA, reserveB)
- getLPBalance(user) → LP shares
- getTotalLPSupply() → total LP shares

---

## 2) MiniDexFactory.sol — The Pool Creator

### Purpose
Creates and registers MiniDexPair instances, prevents duplicates, and exposes discovery helpers.

### Key Imports
- Ownable (OpenZeppelin): onlyOwner guard on createPair
- MiniDexPair: the pool contract template

### State & Events
- event PairCreated(tokenA, tokenB, pairAddress, index)
- getPair[tokenA][tokenB] → pair address (stored symmetrically for both orders)
- allPairs (address[]): list of all pair addresses

### Construction
- Owner is set at deployment (flexible assignment via Ownable constructor)

### Functions
- createPair(_tokenA, _tokenB) onlyOwner returns (pair)
  - Validates non-zero, non-identical addresses; rejects if already exists
  - Sorts addresses (token0 < token1) for canonical storage
  - Deploys new MiniDexPair(token0, token1)
  - Stores mapping both directions; appends to allPairs; emits PairCreated

- allPairsLength() → count
- getPairAtIndex(index) → pair address

---

## Fee Model and AMM Behavior

- Fee: 0.3% per swap (Uniswap V2-style), implicit in 997/1000 factor
- Slippage: Larger trades move price along the x*y=k curve; output decreases with size
- Invariance: Swaps keep product near constant; reserves never fully drain
- LP Ownership: LP shares represent proportional claims; minting and burning maintain fairness

---

## Security Notes

- ReentrancyGuard: critical around token flow functions (add/remove/swap)
- Reserve caching: always sync after token movements to avoid stale math and manipulation
- Input validation: enforce token membership, non-zero amounts, and existing balances

---

## Minimal Mock Token (for Remix testing)

Use OpenZeppelin ERC20 for quick setup:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply)
        ERC20(name, symbol)
    {
        _mint(msg.sender, initialSupply);
    }
}
```

---

## Remix: Quick Start

1) Create and deploy two mock ERC-20 tokens with large initial supplies.
2) Deploy MiniDexPair(tokenA, tokenB) directly or use MiniDexFactory to create the pair.
3) Approve the pair address on both tokens for sufficient amounts.
4) addLiquidity(amountA, amountB); verify via getReserves and getLPBalance.
5) Preview swaps with getAmountOut; then swap(inputAmount, inputToken).
6) removeLiquidity(lpAmount) to redeem proportional reserves.
7) Observe events in Remix logs: LiquidityAdded, LiquidityRemoved, Swapped.
8) For multiple pools, use Factory: createPair, getPair, allPairsLength, getPairAtIndex.

---

## Practical Tips and Small Reconciliations

- Token order: Factory canonicalizes pairs by sorting addresses; the Pair itself treats tokenA/tokenB as immutable constructor inputs. Query via getPair in either order.
- LP accounting: LP tokens are tracked internally (mapping + total supply) rather than implemented as a transferable ERC-20. This keeps the tutorial minimal; upgrading to an ERC-20 LP is possible later.
- Reserves vs. balanceOf: Reserves are cached from actual balances post-actions; always call _updateReserves() after token transfers.
- Fee destination: The 0.3% fee stays in the pool and accrues to LPs implicitly via price impact (no separate fee vault in this minimal design).

---

## What You’ll Learn

- How constant product AMMs price swaps and handle slippage
- How to mint and burn LP shares fairly (initial geometric mean and proportional minting)
- How to manage reserves safely and prevent reentrancy
- How to scale pools with a factory while avoiding duplicates

Builder mode on. This Mini DEX is intentionally minimal yet production-aware in its guardrails and math. Extend it with ERC-20 LP tokens, protocol fees, TWAP oracles, or governance as next steps.