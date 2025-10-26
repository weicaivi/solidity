# TipJar: A Multi‑Currency Tipping Smart Contract

A developer loved your dApp and wants to tip—but only in USD. How can they send you ETH value using a fiat amount? Enter TipJar: a smart contract that accepts tips in ETH directly or as fiat-denominated amounts (USD/EUR/JPY/GBP), converted to ETH on-chain using owner‑set rates.

---

## What We’ll Learn

- Work in wei (the smallest unit of ETH) and why Solidity avoids decimals
- Store and update fiat -> ETH conversion rates safely
- Accept tips in ETH and in fiat amounts (converted to ETH)
- Track totals per currency, per tipper, and overall
- Withdraw tips securely; transfer ownership
- Read-only utility functions for dashboards

---

## Key Concepts

### ETH vs. Wei
- Solidity doesn’t support decimals; all ETH math is done in integers.
- 1 ETH = 10^18 wei.
- Example: 0.05 ETH = 0.05 × 10^18 = 5 × 10^16 wei.
- Store conversion rates scaled to wei so multiplication stays in integer space.

### Manual Conversion Rates
- Smart contracts don’t fetch real-world prices by default.
- The owner sets rates like “1 USD = 0.0005 ETH” by storing 5×10^14 wei per USD unit.
- Future improvement: integrate an oracle (e.g., Chainlink) for live rates.

---

## Contract Overview

State:
- owner: contract admin
- conversionRates: mapping currency code (string) → wei per unit
- supportedCurrencies: array of currency codes for iteration
- totalTipsReceived: cumulative ETH received (wei)
- tipperContributions: mapping address → total ETH tipped (wei)
- tipsPerCurrency: mapping currency code → total fiat amount tipped (as entered)

Access control:
- onlyOwner modifier for admin actions (add/update rates, withdrawals, ownership transfer)

Core flows:
1. Add/update currency rate: addCurrency(code, rateWeiPerUnit)
2. Tip in ETH directly: tipInEth() payable
3. Tip by fiat amount: tipInCurrency(code, amount) payable
   - Compute expected wei via convertToEth()
   - Require msg.value equals the computed wei
4. Withdraw funds: withdrawTips() onlyOwner
5. Transfer ownership: transferOwnership(newOwner)

Utilities:
- getSupportedCurrencies()
- getContractBalance()
- getTipperContribution(address)
- getTipsInCurrency(code)
- getConversionRate(code)

---

## Representative Implementation

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title TipJar - Accept ETH tips and fiat-denominated tips converted to ETH
/// @notice Owner sets conversion rates; all ETH accounting uses wei
contract TipJar {
    // --- Admin ---
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        // Preload sample rates (wei per unit of fiat)
        // Example: 1 USD = 0.0005 ETH => 5 * 10^14 wei
        addCurrency("USD", 5 * 10**14);
        addCurrency("EUR", 6 * 10**14);
        addCurrency("JPY", 4 * 10**12);
        addCurrency("GBP", 7 * 10**14);
    }

    // --- Rates & Supported Currencies ---
    mapping(string => uint256) public conversionRates;     // fiat unit -> wei
    string[] public supportedCurrencies;

    /// @dev Add or update a currency code and its wei-per-unit rate
    function addCurrency(string memory _currencyCode, uint256 _rateToEth)
        public
        onlyOwner
    {
        require(_rateToEth > 0, "Rate must be > 0");

        bool exists = false;
        for (uint i = 0; i < supportedCurrencies.length; i++) {
            if (
                keccak256(bytes(supportedCurrencies[i])) ==
                keccak256(bytes(_currencyCode))
            ) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            supportedCurrencies.push(_currencyCode);
        }
        conversionRates[_currencyCode] = _rateToEth;
    }

    // --- Accounting ---
    uint256 public totalTipsReceived;                       // ETH received (wei)
    mapping(address => uint256) public tipperContributions; // per-address (wei)
    mapping(string => uint256) public tipsPerCurrency;      // fiat totals (as entered)

    // --- Conversion ---
    function convertToEth(string memory _currencyCode, uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256 rate = conversionRates[_currencyCode];
        require(rate > 0, "Currency not supported");
        // amount (fiat units) * wei-per-unit => wei expected
        return _amount * rate;
    }

    // --- Tipping ---
    /// @notice Tip directly in ETH
    function tipInEth() public payable {
        require(msg.value > 0, "Tip must be > 0");
        tipperContributions[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency["ETH"] += msg.value; // track ETH separately
    }

    /// @notice Tip by fiat amount; must send exact ETH (in wei) matching conversion
    /// @param _currencyCode e.g., "USD"
    /// @param _amount fiat amount (integer, scaled as you choose)
    function tipInCurrency(string memory _currencyCode, uint256 _amount)
        public
        payable
    {
        require(_amount > 0, "Amount must be > 0");

        uint256 expectedWei = convertToEth(_currencyCode, _amount);
        require(msg.value == expectedWei, "ETH sent must equal converted wei");

        tipperContributions[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency[_currencyCode] += _amount; // keep original fiat intention
    }

    // --- Withdrawals ---
    /// @notice Withdraw all ETH tips to owner
    function withdrawTips() public onlyOwner {
        uint256 bal = address(this).balance;
        require(bal > 0, "No tips to withdraw");
        (bool ok, ) = payable(owner).call{value: bal}("");
        require(ok, "Transfer failed");
        // Reset running total (optional bookkeeping)
        totalTipsReceived = 0;
    }

    // --- Ownership ---
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
    }

    // --- View Helpers ---
    function getSupportedCurrencies() public view returns (string[] memory) {
        return supportedCurrencies;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTipperContribution(address _tipper) public view returns (uint256) {
        return tipperContributions[_tipper];
    }

    function getTipsInCurrency(string memory _currencyCode) public view returns (uint256) {
        return tipsPerCurrency[_currencyCode];
    }

    function getConversionRate(string memory _currencyCode) public view returns (uint256) {
        uint256 rate = conversionRates[_currencyCode];
        require(rate > 0, "Currency not supported");
        return rate;
    }
}
```

---

## Usage Examples

- Set or update a rate (owner only):
  - USD: 1 USD = 0.0005 ETH → rate = 5 × 10^14 wei
  - `addCurrency("USD", 5 * 10**14)`

- Convert and tip in fiat:
  - User enters 2000 USD
  - Expected wei = 2000 × 5 × 10^14 = 10^18 wei (1 ETH)
  - Frontend sends transaction to `tipInCurrency("USD", 2000)` with `msg.value = 10^18`

- Tip in ETH directly:
  - Call `tipInEth()` and attach ETH in `msg.value`

- Withdraw:
  - Owner calls `withdrawTips()` to transfer all ETH to `owner`

---

## Frontend Notes

- Do all display formatting off-chain:
  - Show ETH values by dividing wei by 10^18 for human-readable output.
- Prevent rounding errors:
  - Keep all on-chain math in integers (wei).
- Include rate validation on UI:
  - Fetch `getConversionRate(code)` before computing required `msg.value`.

---

## Design Decisions & Safety

- String comparison via keccak256(bytes(...)) to avoid Solidity’s lack of `==` for strings.
- Use `call{value: ...}("")` for withdrawals to be compatible with contracts and handle gas-forwarding.
- Require exact `msg.value` match for fiat-tips to prevent mispayments.
- Expose read-only views for dashboards without gas costs.

---

## Future Improvements

- Add events (tips, rate updates, withdrawals) for analytics.
- Integrate Chainlink oracles for live currency rates.
- Support more currencies and crypto assets.
- Add multi-sig ownership for treasury safety.
- Consider enums or bytes32 for currency keys to save gas.

---

## Quick FAQ

- Why not decimals? Solidity avoids floating point; use wei integers.
- Can I store cents? Yes—define your UI unit (e.g., cents) and scale the rate accordingly.
- Is USD actually transferred? No, fiat is simulated via conversion; users still send ETH on-chain.

---

## Glossary

- Wei: the smallest ETH unit (1 ETH = 10^18 wei).
- msg.value: ETH (wei) attached to a payable function call.
- onlyOwner: restricts functions to the contract owner.
- Oracle: off-chain data provider for on-chain contracts (e.g., currency prices).

