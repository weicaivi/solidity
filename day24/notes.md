# EnhancedSimpleEscrow — A Practical Decentralized Escrow Contract

Welcome to Day 24 of Solidity. Today’s goal: build a real, trustless escrow you can use in marketplaces, freelance jobs, and NFT trades. The contract securely holds ETH, enforces delivery, supports disputes with an arbiter, and includes timeouts and clean events for frontends.

## What Is Escrow?

Escrow is a middleman holding funds until agreed conditions are met. In Web3, we replace companies like PayPal with code: transparent rules executed on-chain.

## Overview

Contract: `EnhancedSimpleEscrow`

Key features:
- Holds ETH until the buyer confirms delivery.
- Either party can raise a dispute.
- A neutral arbiter resolves disputes by releasing funds to buyer or seller.
- Built-in delivery timeout to protect buyers.
- Mutual cancellation path (buyer or seller can cancel before completion).
- Clean events and read-only helpers for frontend integration.


## Roles

- Buyer: deploys the contract and deposits ETH.
- Seller: delivers goods/services; receives payment on confirmation or dispute resolution in their favor.
- Arbiter: resolves disputes, selecting buyer or seller as recipient.

## States

`AWAITING_PAYMENT` → `AWAITING_DELIVERY` → `COMPLETE` or `DISPUTED` → `COMPLETE`  
Cancellation paths: `AWAITING_PAYMENT`/`AWAITING_DELIVERY` → `CANCELLED` (mutual or timeout).

## Events (for frontend/monitoring)

- `PaymentDeposited`: escrow started; shows amount locked.
- `DeliveryConfirmed`: buyer confirmed; funds sent to seller.
- `DisputeRaised`: a dispute began; UI can switch to “Disputed”.
- `DisputeResolved`: arbiter decision; shows recipient and amount.
- `EscrowCancelled`: escrow ended by timeout or mutual agreement.
- `DeliveryTimeoutReached`: buyer canceled after deadline.

## Function-by-Function Behavior

- `deposit()` — Buyer locks ETH; state moves to AWAITING_DELIVERY; timestamp recorded.
- `confirmDelivery()` — Buyer marks completion; ETH transfers to seller; state COMPLETE.
- `raiseDispute()` — Buyer or seller escalates; state DISPUTED; funds frozen.
- `resolveDispute(bool _releaseToSeller)` — Arbiter finalizes: send to seller if `true`, else refund buyer; state COMPLETE.
- `cancelAfterTimeout()` — Buyer cancels if delivery window expired; refund; emits timeout.
- `cancelMutual()` — Buyer or seller cancels early; if funds were deposited, buyer is refunded; state CANCELLED.
- `getTimeLeft()` — Remaining seconds until timeout during AWAITING_DELIVERY; 0 otherwise.

## User Flow (Simplified)

1. Deploy contract (buyer provides seller, arbiter, deliveryTimeout).
2. Buyer calls `deposit()` with ETH.
3. Seller delivers off-chain.
4. Buyer either:
   - calls `confirmDelivery()` → seller paid; COMPLETE, or
   - calls `raiseDispute()` → arbiter calls `resolveDispute(...)`, or
   - after timeout, calls `cancelAfterTimeout()` → refund.
5. Alternatively, buyer or seller calls `cancelMutual()`:
   - if deposited → refund buyer; CANCELLED,
   - if not deposited → just CANCELLED.

## Design Notes and Security Considerations

- Direct ETH transfers are rejected via `receive()` to enforce deposits through `deposit()` and keep state consistent.
- Timeouts use `block.timestamp`; ensure reasonable windows (e.g., days) to avoid premature cancellations.
- Use events to drive frontend state and notifications.
- For production, consider:
  - Reentrancy protections and Checks-Effects-Interactions pattern (here, external calls are only simple `transfer`; for more complex payouts consider `call` and reentrancy guards).
  - Escrow fee/royalty logic if needed (not included here).
  - Upgradability and role management if used in a broader marketplace.

## Example Scenario

- Buyer (Alice) deploys with seller (Bob), arbiter (Charlie), and timeout of 3 days.
- Alice deposits 2 ETH → state AWAITING_DELIVERY.
- Paths:
  - Happy path: Alice confirms → Bob receives 2 ETH → COMPLETE.
  - Dispute: Alice or Bob raises → Charlie resolves to buyer or seller → COMPLETE.
  - Timeout: 3 days pass without delivery → Alice cancels → refund → CANCELLED.
  - Mutual cancel: Alice or Bob cancels early → refund if funds locked → CANCELLED.

## Why This Pattern Works

- Trustless: rules enforced by code.
- Transparent: events and state transitions are verifiable on-chain.
- Safe defaults: funds only move when the right party triggers the right function in the right state.