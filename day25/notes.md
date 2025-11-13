# Automated Market Maker (AMM)

A constant-product AMM is the math-driven engine behind decentralized exchanges (DEXs) like Uniswap V2. Instead of matching buyers and sellers via an order book, users trade directly against a liquidity pool held by a smart contract.

This guide explains the AMM concept and provides a compact Solidity implementation you can test in Remix.

## Why AMMs?

On-chain order books are gas-heavy, slow, and require always-on counterparties. AMMs replace them with:
- A pool of two ERC‑20 tokens (e.g., Token A and Token B).
- Deterministic pricing based on reserves.
- Permissionless operations: add/remove liquidity and swap.

## Core Concept: x * y = k

- x = reserve of Token A
- y = reserve of Token B
- k = constant product

Trades adjust x and y such that their product stays (approximately) constant. Larger trades cause more price impact (slippage), because they move along the curve.

A small swap of Token A in:
- Input is fee-adjusted (e.g., 0.3% fee).
- Output of Token B is calculated from current reserves.
- Reserves update to reflect the trade.

## What Users Can Do

- Swap A ↔ B
  - Provide an input amount and a minimum acceptable output (slippage protection).
- Add Liquidity
  - Deposit both tokens in proportion to current reserves.
  - Receive LP tokens representing your share.
- Remove Liquidity
  - Burn LP tokens to redeem your proportional share of both tokens.

## Contract Overview

- Inherits ERC20 to issue LP tokens.
- Tracks reserves for pricing and accounting.
- Emits events for front-end indexing and UX.

### State
- tokenA, tokenB: ERC‑20 token interfaces
- reserveA, reserveB: current pool reserves
- owner: deployer address (placeholder for governance/emergency controls)

### Key Events
- LiquidityAdded(provider, amountA, amountB, liquidity)
- LiquidityRemoved(provider, amountA, amountB, liquidity)
- TokensSwapped(trader, tokenIn, amountIn, tokenOut, amountOut)

### Fee
- 0.3% swap fee (997/1000 multiplier) retained in the pool, accruing to LPs.


## User Flows (High Level)

1) Initialize Pool
- Deploy with Token A and Token B addresses, LP token name/symbol.

2) Add Liquidity
- User approves AMM for A and B.
- AMM pulls tokens, mints LP:
  - If first deposit: mint sqrt(A × B).
  - Else: mint proportionally using min() against current reserves.
- Update reserves and emit LiquidityAdded.

3) Remove Liquidity
- User burns LP; AMM returns proportional A and B.
- Update reserves and emit LiquidityRemoved.

4) Swap A → B
- User approves AMM for A.
- Apply 0.3% fee; compute output via constant product.
- Enforce min output; update reserves; emit TokensSwapped.

5) Swap B → A
- Mirror of A → B.

6) Query
- getReserves() for price UI, analytics, and slippage estimation.

## Practical Notes

- Slippage: Larger swaps relative to pool size cause worse price; always set minOut.
- Fees: Accrue to liquidity providers via growing reserves.
- LP Accounting: LP tokens track ownership; more volume = more fees = larger redeemable share.
- Safety: This minimal AMM omits reentrancy guards, oracle checks, and fee routing. For production, add:
  - Reentrancy protection
  - Pausable/emergency controls
  - Robust math and input validation
  - Permit-like flows to reduce approvals (optional)

## Test in Remix

1) Deploy two test ERC‑20 tokens (e.g., Token A and Token B with 18 decimals).
2) Deploy AutomatedMarketMaker with those addresses and LP metadata.
3) approve(AMM, amount) on both tokens.
4) addLiquidity(100e18, 100e18) to seed the pool.
5) swapAforB(10e18, minBOut) to trade; adjust minBOut to avoid reverts.
6) removeLiquidity(lpAmount) to redeem your share.
7) Observe events and reserves to verify behavior.

## Glossary

- Constant Product AMM: Pricing rule x * y = k governing swaps.
- LP Token: ERC‑20 representing pool ownership.
- Reserves: Internal accounting of token balances used for pricing.
- Slippage: Difference between expected and actual execution price.
- Price Impact: The curve movement caused by your trade size.

## Scope & Consistency

- Reserves are updated explicitly on each action; do not derive them from token balances.
- Fee is applied to input before output calculation; fee portion remains in the pool.
- Initial LP mint uses geometric mean (sqrt), ensuring fair start conditions.
- Swaps require user-set minimum output for slippage protection.
