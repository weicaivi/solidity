# AuctionHouse

## What we’re building
An on-chain auction where:
- The contract owner lists an item.
- Users place bids (numeric amounts).
- The highest bid wins when the auction ends.
- Key info is hidden until the auction is finished.

## Core concepts
- Global variables: `msg.sender`, `block.timestamp`
- Visibility: `public`, `private`, `external`, `view`
- State types: `string`, `uint`, `address`, arrays, mappings
- Control: `require()` for rule enforcement
- Constructor: initialize contract state once

---

## Contract overview

### State variables
- `owner (address, public)`: who deployed the contract; the auction administrator.
- `item (string, public)`: human-readable name of the thing being auctioned.
- `auctionEndTime (uint, public)`: timestamp when bidding must stop.
- `highestBidder (address, private)`: leader’s address (hidden until the end).
- `highestBid (uint, private)`: current top bid (hidden until the end).
- `ended (bool, public)`: whether the auction was formally ended.
- `bids (mapping(address => uint), public)`: each participant’s latest bid.
- `bidders (address[], public)`: list of unique participants (first-time bidders only).

### Constructor
- Sets `owner` to `msg.sender`.
- Stores `_item` as `item`.
- Sets `auctionEndTime` to `block.timestamp + _biddingTime` (seconds).

Example: `_biddingTime = 300` → ends 5 minutes from deployment.

### Bidding rules
- You can’t bid after the end time.
- Bid must be > 0.
- Your new bid must be strictly higher than your previous bid.
- First-time bidders are added to `bidders`.
- If your bid beats the current `highestBid`, you become the `highestBidder`.

### Ending the auction
- Can only end after `auctionEndTime`.
- Can only end once (guarded by `ended` flag).
- Flips `ended = true`.

### Reading results
- `getWinner()` returns `(highestBidder, highestBid)` only after `ended == true`.
- `getAllBidders()` returns the `bidders` array.

---

## Implementation

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AuctionHouse {
    address public owner;
    string public item;
    uint public auctionEndTime;

    address private highestBidder;
    uint private highestBid;

    bool public ended;

    mapping(address => uint) public bids;
    address[] public bidders;

    constructor(string memory _item, uint _biddingTime) {
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    function bid(uint amount) external {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        require(amount > 0, "Bid amount must be greater than zero.");
        require(amount > bids[msg.sender], "New bid must be higher than your current bid.");

        if (bids[msg.sender] == 0) {
            bidders.push(msg.sender);
        }

        bids[msg.sender] = amount;

        if (amount > highestBid) {
            highestBid = amount;
            highestBidder = msg.sender;
        }
    }

    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction hasn't ended yet.");
        require(!ended, "Auction end already called.");

        ended = true;
    }

    function getWinner() external view returns (address, uint) {
        require(ended, "Auction has not ended yet.");
        return (highestBidder, highestBid);
    }

    function getAllBidders() external view returns (address[] memory) {
        return bidders;
    }
}
```

---

## Design notes and trade-offs

- Privacy of leader info: `highestBid` and `highestBidder` are `private` to discourage gaming; exposed only after `ended`.
- Simplicity over funds custody: This version tracks numbers only; it does NOT accept or hold ETH. In production, prefer payable bids with escrow and a withdrawal pattern (pull payments).
- Single-bid overwrite: A bidder’s latest bid replaces their previous bid in `bids`. If you use payable ETH, store the sum sent or enforce increments.
- Time-based control: `block.timestamp` is good enough for coarse-grained deadlines; don’t rely on it for sub-second precision.
- One-time actions: The `ended` boolean prevents re-entrance of the end step.

---

## Safe extensions to consider

- Minimum increment rule: e.g., enforce `amount >= highestBid * 105 / 100` for 5% steps.
- Starting price: require `amount >= reservePrice`.
- Payable bidding with refunds:
  - Accept ETH via `bid()` (payable).
  - Track balances.
  - Non-winners withdraw via a separate `withdraw()` function (Checks-Effects-Interactions).
- Role control:
  - Only `owner` can end the auction or set parameters.
- Events:
  - Emit events for `BidPlaced`, `AuctionEnded`, to index activity off-chain.

---

## Quick checklist (before deployment)

- Parameters:
  - `item` is clear and human-readable.
  - `_biddingTime` (seconds) matches your auction length.
- Test cases:
  - Bid before end → OK.
  - Bid after end → reverts.
  - Lower/equal bid → reverts.
  - First-time bidder → gets added to `bidders`.
  - End auction once → OK; twice → reverts.
  - Read `getWinner()` only after `ended == true`.

---

## Common pitfalls

- Making `getWinner()` callable before the auction ends.
- Forgetting to guard `endAuction()` with `ended` flag.
- Not handling ETH safely when making bids payable (use withdrawal patterns, avoid direct refunds in the same call).
- Off-by-one timing errors — test near deadline.

---
