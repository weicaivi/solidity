# SimpleLending: A Minimal ETH Lending Pool

A polished, simplified English overview merging the core ideas of the English tutorial with the structured detail from the Chinese version. The goal is clarity, technical accuracy, and consistent terminology.

## What This Is

**SimpleLending** is a compact, ETH‑only lending pool demonstrating core **DeFi** mechanics without ERC‑20 tokens or price oracles. Users can:
- Deposit ETH into a pool.
- Lock ETH as collateral.
- Borrow ETH against that collateral.
- Accrue and repay interest over time.
- Withdraw deposits and, if safe, withdraw collateral.

This design emphasizes concepts over production‑grade features.

## Key Concepts

- **Separate balances:** Deposits and collateral are tracked independently. Deposits are liquid funds you can withdraw; collateral is ETH locked to secure borrowing.
- **Over‑collateralized borrowing:** A **75% LTV** cap (collateral factor) limits borrowing to keep positions safe.
- **Time‑based interest:** A **5% APR** (500 basis points) accrues linearly over elapsed time, calculated on demand to save gas.
- **Event‑driven UI:** Emits events for deposits, withdrawals, borrows, repays, and collateral changes.

## Protocol Parameters

- **Interest:** 500 basis points (5% annual interest).
- **Collateral factor:** 7500 basis points (75% LTV).
- **Liquidity:** The pool’s available ETH is the contract’s balance.

## Events

- **Deposit / Withdraw:** Track pool inflows/outflows from deposit balances.
- **Borrow / Repay:** Track user debt lifecycle and interest accrual checkpoints.
- **CollateralDeposited / CollateralWithdrawn:** Track collateral movements and safety checks.

## Core Functions (Behavior Summary)

- **deposit():** Add ETH to your deposit balance. Emits Deposit.
- **withdraw(amount):** Withdraw from your deposit balance if sufficient. Emits Withdraw.
- **depositCollateral():** Lock ETH as collateral to enable borrowing. Emits CollateralDeposited.
- **withdrawCollateral(amount):** Withdraw collateral only if your post‑withdrawal collateral still covers your up‑to‑date debt at the required LTV. Emits CollateralWithdrawn.
- **borrow(amount):** Borrow ETH up to your current collateral limit, factoring in any existing debt plus accrued interest. Sets the last interest accrual timestamp. Emits Borrow.
- **repay():** Send ETH to reduce or clear your debt (principal + accrued interest). Any overpayment is refunded automatically. Updates accrual timestamp. Emits Repay.
- **calculateInterestAccrued(user):** Returns the user’s current debt including linear accrued interest since the last timestamp.
- **getMaxBorrowAmount(user):** Returns collateral × collateral factor (upper bound before considering existing debt).
- **getTotalLiquidity():** Returns contract ETH balance (pool liquidity).

## Interest Calculation (On‑Demand, Linear)

Interest accrues when needed (borrow/repay/checks), not continuously. For a user with debt:
- timeElapsed = now − lastAccrualTimestamp
- interest = principal × rateBPS × timeElapsed ÷ (10000 × 365 days)
- totalDebt returned = principal + interest

This is **simple (non‑compounding)** interest for clarity and gas efficiency.

## Borrowing Limits and Collateral Safety

- Max borrowable at any moment: collateral × collateral factor.
- Withdrawals of collateral simulate the post‑withdrawal state and revert if it violates the required LTV given the user’s up‑to‑date debt (including interest).

## System Flow (Simplified)

1. **Deposit ETH** → balance increases → pool liquidity increases.
2. **Lock collateral** → borrowing power becomes available.
3. **Borrow ETH** → checks liquidity + LTV → debt recorded, timestamp set.
4. **Interest accrues** → computed on demand using elapsed time.
5. **Repay debt** → reduces principal; refunds any overpayment; resets timestamp.
6. **Withdraw collateral** → allowed only if safe at required LTV.
7. **Withdraw deposit** → allowed if deposit balance is sufficient.

## Contract API Surface

| Function | Visibility | Mutability | Purpose |
| --- | --- | --- | --- |
| deposit | external | payable | Add ETH to deposit balance. |
| withdraw | external | nonpayable | Withdraw deposited ETH if sufficient balance. |
| depositCollateral | external | payable | Lock ETH as collateral. |
| withdrawCollateral | external | nonpayable | Withdraw collateral if safe post‑withdrawal. |
| borrow | external | nonpayable | Borrow ETH within collateralized limit. |
| repay | external | payable | Repay debt; auto‑refund excess. |
| calculateInterestAccrued | public | view | Get current debt with interest. |
| getMaxBorrowAmount | external | view | Upper bound based on collateral only. |
| getTotalLiquidity | external | view | Contract ETH balance. |


## Notes on Limitations and Safety (Educational Context)

- **Deposits vs. debt:** In this minimal design, deposit withdrawals do not consider outstanding debt; they only check deposit balance. This keeps concepts separate but allows depositors to withdraw even if they’ve borrowed (potentially reducing pool liquidity). Production systems typically couple these or add reserve rules.
- **.transfer gas stipend:** Using `transfer` is simple but can fail for contracts needing more than 2300 gas in `receive`. Many modern systems prefer `call{value: ...}("")` with checks.
- **No liquidations / price feeds:** LTV assumes collateral and debt are both ETH, with no market volatility handling. Real protocols add price oracles and liquidation mechanisms.
- **No reentrancy guards:** The use of `transfer` mitigates reentrancy on value sends, but comprehensive protection (e.g., `ReentrancyGuard`, CEI pattern) is recommended in production.
- **Interest is linear (non‑compounding):** This keeps math and gas simple for learning.

## Getting Started (Suggested Flow)

1. **Fund the pool:** Use `deposit()` from multiple accounts to add liquidity.
2. **Lock collateral:** Call `depositCollateral()` from the borrower account.
3. **Borrow ETH:** Use `borrow(amount)` within the 75% LTV limit.
4. **Wait or interact:** Time passes; interest accrues on demand.
5. **Repay debt:** Call `repay()` with enough ETH; excess is refunded.
6. **Withdraw collateral/deposits:** If safe at required LTV, withdraw collateral; deposits can be withdrawn with sufficient balance.