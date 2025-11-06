# Oracle-Powered Crop Insurance in Solidity

A practical guide to building a mock oracle and a crop insurance contract that reacts to rainfall data. You’ll learn what oracles are, how Chainlink-style feeds work, and how to wire an insurance payout to live (or simulated) data.

---

## 1) Why Smart Contracts Need Oracles

Smart contracts are deterministic and isolated: they can’t read off-chain data directly (prices, weather, sports scores). Oracles bridge that gap by securely delivering external data to on-chain contracts.

- Analogy: An oracle is a trusted courier delivering real-world facts to your contract.
- Popular choice: Chainlink provides decentralized data feeds (prices, weather, VRF randomness, etc.) via standard interfaces like `AggregatorV3Interface`.

In this tutorial, we’ll simulate a rainfall oracle in the style of Chainlink, then consume it from a crop insurance contract. Later, you can swap the mock with a real Chainlink feed.

---

## 2) What You’ll Build

- MockWeatherOracle.sol
  - A Chainlink-style oracle that returns a pseudo-random rainfall value (0–999 mm).
  - Implements `AggregatorV3Interface` so downstream contracts can call `latestRoundData()`.

- CropInsurance.sol
  - Lets a farmer purchase insurance by paying a premium (priced in USD, converted to ETH via an ETH/USD feed).
  - Periodically checks rainfall and pays out automatically when it’s below a threshold.

---

## 3) Mock Oracle: Design

### Goals
- Match Chainlink’s `AggregatorV3Interface` shape so downstream integration is trivial.
- Provide round/timestamp metadata and a fresh value per update cycle.
- Keep it simple and explicitly “mock” (no secure randomness).

### Interface
- `decimals()` -> 0 (we report whole millimeters)
- `description()` -> "MOCK/RAINFALL"
- `version()` -> 1
- `getRoundData(roundId)` and `latestRoundData()`
  - Return `(roundId, rainfall, startedAt, updatedAt, answeredInRound)`.

### Randomness (Mock Only)
- Compute rainfall via a hash of block parameters, then mod 1000 to yield `0–999`.
- Note: This is pseudo-random and not secure—fine for testing but not production.

### Update Mechanics
- `updateRandomRainfall()` increments `_roundId` and updates `_timestamp` and `_lastUpdateBlock`.
- Each update represents a new “data round” (like a fresh reading).

### Recommended Cleaned-Up Declaration (key fields)
- `_decimals = 0`
- `_description = "MOCK/RAINFALL"`
- `_roundId = 1`
- `_timestamp = block.timestamp`
- `_lastUpdateBlock = block.number`

---

## 4) Crop Insurance: Design

### Constants (example values)
- `RAINFALL_THRESHOLD = 500` (mm)
- `INSURANCE_PREMIUM_USD = 10`
- `INSURANCE_PAYOUT_USD = 50`

### External Feeds
- `weatherOracle`: our mock rainfall feed (implements `AggregatorV3Interface`)
- `ethUsdPriceFeed`: a Chainlink ETH/USD feed

### Core Flows

1) Purchase Insurance
   - Convert USD premium to ETH using `ethUsdPriceFeed.latestRoundData()`.
   - Require `msg.value >= premiumInEth`.
   - Mark caller as insured.

2) Check & Claim
   - Require the caller is insured and respects a cooldown (e.g., 24 hours).
   - Read rainfall via `weatherOracle.latestRoundData()`.
   - Validate freshness (e.g., `updatedAt > 0` and `answeredInRound >= roundId`).
   - If `rainfall < RAINFALL_THRESHOLD`, calculate payout in ETH and transfer.

3) Utilities
- `getEthPrice()` returns the raw feed value (commonly 8 decimals for Chainlink price feeds).
- `getCurrentRainfall()` reads the oracle and returns rainfall as `uint256`.
- `withdraw()` for owner to collect the contract balance.
- `receive()` and `getBalance()` for ETH handling and transparency.

### Decimal Handling (ETH/USD)
- Chainlink ETH/USD feeds typically return an 8-decimal number (e.g., `254000000000` for $2,540.00000000).
- When converting USD → ETH for on-chain math:
  - Keep everything in wei.
  - If `ethPrice` has 8 decimals, you’ll often multiply by `1e18` and divide by `ethPrice * 1e8` to normalize correctly.
  - In this tutorial, we treat `ethPrice` as the raw feed value and normalize appropriately in the conversion formulas.

---

## 5) Example Conversion Formulas

Assume:
- `ethPrice` is from `latestRoundData()` and has 8 decimals.
- USD amounts are whole numbers (`INSURANCE_PREMIUM_USD`, `INSURANCE_PAYOUT_USD`).

Then:
- `premiumInEthWei = (INSURANCE_PREMIUM_USD * 1e18 * 1e8) / ethPrice`
- `payoutInEthWei  = (INSURANCE_PAYOUT_USD  * 1e18 * 1e8) / ethPrice`

This keeps math in integers and accounts for the feed’s 8 decimal places.

---

## 6) Data Freshness and Safety

- Always check `updatedAt > 0` (round completed).
- Verify `answeredInRound >= roundId` to avoid stale rounds.
- Emit events (purchase, rainfall checked, claim submitted, claim paid) for transparency and off-chain indexing.
- Use a claim cooldown (e.g., 24 hours) to discourage spam.
- For payouts, use safe transfer patterns and handle reentrancy if you extend functionality (consider non-reentrant modifiers).

---

## 7) Testing Workflow

1) Deploy `MockWeatherOracle`.
2) Deploy `CropInsurance` with:
   - Address of `MockWeatherOracle`
   - Address of a Chainlink ETH/USD feed (or your own mock)
3) Call `updateRandomRainfall()` on the oracle to simulate new data rounds.
4) `purchaseInsurance()` with enough ETH (converted from USD premium).
5) `checkRainfallAndClaim()` to trigger payout if rainfall is below threshold.
6) Observe events and balances.

---

## 8) Production Notes

- Replace `MockWeatherOracle` with a real Chainlink feed when available:
  - Update `weatherOracle` address to the official feed.
  - Confirm decimals and description.
- For secure randomness (not needed here), use Chainlink VRF.
- Consider access controls, rate limits, slippage/price staleness checks, and reentrancy protection.


---
