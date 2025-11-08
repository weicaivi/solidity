# FortKnox: Reentrancy Attack

A practical, hands-on guide to understanding, exploiting, and defending against reentrancy in Solidity.

## Overview

Reentrancy occurs when a contract makes an external call before it updates its own state, allowing the callee to “re-enter” the same function and repeat privileged operations. Classic consequence: balances are drained because the contract still thinks funds are available.

We built:
- GoldVault.sol: a vault with both vulnerable and secure withdrawals.
- GoldThief.sol: an attacker contract that demonstrates the exploit and why the fix works.


---

## Concept: What Is Reentrancy?

Think of a vending machine that dispenses a snack before it updates your balance. If you press the button again in that tiny window, the machine believes you still have credit and dispenses another snack. In Solidity, this happens when a contract sends ETH (or otherwise calls out) before clearing the user’s balance.

Key risks:
- External call before state update
- Fallback/receive re-enters the same function
- Balance gets paid multiple times

---

## Architecture

### GoldVault.sol (The Vault)
- deposit(): users store ETH.
- vulnerableWithdraw(): sends ETH first, then zeroes balance—vulnerable to reentrancy.
- safeWithdraw(): uses a nonReentrant guard and updates state before sending ETH—secure.

### GoldThief.sol (The Attacker)
- attackVulnerable(): deposits then triggers recursive withdrawals via receive().
- attackSafe(): attempts the same against the guarded function—reentrancy is blocked.
- stealLoot(): transfers stolen ETH to owner.
- getBalance(): reports attacker contract’s current ETH balance.

---

## Secure Design Principles

- Checks-Effects-Interactions pattern:
  1) Check preconditions,
  2) Update internal state,
  3) Interact with external contracts.
- Reentrancy guard: block re-entry while protected code executes.
- Avoid using call patterns that allow arbitrary code execution before your state is safe, or ensure guards/order protect you.

---

## Attack & Defense Flow

### Vulnerable Path
1) Attacker deposits ≥ 1 ETH.
2) Calls vulnerableWithdraw().
3) Vault sends ETH before zeroing balance.
4) Attacker’s receive() triggers and re-calls vulnerableWithdraw().
5) Loop repeats until cap/gas/contract balance stops it.
6) Funds accumulate in GoldThief; attacker calls stealLoot().

### Secure Path
1) Attacker deposits ≥ 1 ETH.
2) Calls safeWithdraw().
3) Vault zeroes balance first (Effects), then sends ETH (Interactions).
4) nonReentrant blocks any attempt to re-enter during execution.
5) Reentrancy fails; only a single correct withdrawal occurs.

---

## Key Takeaways

- Update internal state before any external calls (Checks-Effects-Interactions).
- Use a reentrancy guard to block nested entries during sensitive operations.
- Small ordering mistakes can enable large-scale exploits.
- Testing both attack and defense reinforces secure coding habits.
