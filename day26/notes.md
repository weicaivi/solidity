# NFT Marketplace — A Practical, Secure, On‑Chain Tutorial

This tutorial guides you through building a minimal yet production-minded NFT marketplace in Solidity. It supports listing ERC‑721 NFTs, purchasing with ETH, fee and royalty distribution, and safe transfers with reentrancy protection — all enforced on-chain via a single smart contract.

## Why This Matters

An NFT marketplace is where key Web3 concepts converge:
- ERC‑721 interactions (ownership, approvals, transfers)
- Secure ETH handling and payout splits
- Creator royalties (basis points)
- Marketplace fee distribution
- Reentrancy protection with ReentrancyGuard
- Clear ownership and admin controls

You’re not copying OpenSea; you’re understanding its core and implementing a lean version you control.

## What You’ll Build

A Solidity contract that allows:
- Listing any ERC‑721 with a custom price and optional royalty
- Buying with ETH; automatic distribution to seller, creator (royalty), and marketplace (fee)
- Unlisting by the seller
- Admin updates to fee percent and fee recipient
- Emitting events so frontends/indexers can track activity

## Contract Overview

Key components:
- Imports: IERC721 for NFT interactions; ReentrancyGuard for security
- Admin state: owner, marketplaceFeePercent (basis points), feeRecipient
- Listing store: nested mapping by nftAddress and tokenId
- Events: Listed, Purchase, Unlisted, FeeUpdated
- Core functions: listNFT, buyNFT, cancelListing, getListing
- Guards: nonReentrant on purchases; strict validation; receive/fallback reverts


## Key Concepts and Design Choices

### Imports
- IERC721: Interact with any ERC‑721 contract (ownerOf, safeTransferFrom, approvals).
- ReentrancyGuard: Protects state-changing ETH flows with `nonReentrant`, especially in `buyNFT`.

### Admin State
- owner: Deployer; controls fees and recipient updates.
- marketplaceFeePercent: Basis points (bp). 100 bp = 1%; 1000 bp = 10% max.
- feeRecipient: Address receiving marketplace fees; must be non-zero.

### Listings Model
- Struct includes seller, NFT contract, tokenId, price (wei), optional royaltyReceiver, royaltyPercent (bp), isListed flag.
- Mapping is nested by nftAddress and tokenId to support multiple collections.

### Events
- Listed: Logs listing metadata for UIs/indexers.
- Purchase: Logs buyer, amounts, fee and royalty splits.
- Unlisted: Signals removal from sale.
- FeeUpdated: Tracks admin changes to fee settings.

### Validations and Safety
- Ownership and approval checks before listing.
- Exact ETH match on purchase (`msg.value == price`).
- Combined fee + royalty capped at ≤ 100% (≤ 10000 bp).
- Non-zero recipient guards; receive/fallback revert to prevent stray ETH.
- NonReentrant on purchase to prevent reentrancy exploits around ETH transfers and state updates.

## Basis Points (bp) Quick Reference

- 1 bp = 0.01%
- 100 bp = 1%
- 250 bp = 2.5%
- 1000 bp = 10% (max for fees and royalties in this design)

## Testing on Remix (Quick Guide)

1. Compile both contracts:
   - Your ERC‑721 (e.g., SimpleNFT) for minting
   - NFTMarketplace
2. Deploy:
   - SimpleNFT → copy its address
   - NFTMarketplace with:
     - marketplaceFeePercent: 250 (2.5%)
     - feeRecipient: your address
3. Mint and approve:
   - Mint tokenId 0 and 1 in SimpleNFT
   - Call `setApprovalForAll(marketplaceAddress, true)`
4. List:
   - `listNFT(nftAddress, 0, 1000000000000000000, royaltyReceiver, 500)`
     - Price = 1 ETH in wei
     - Royalty = 5% (500 bp)
5. Buy:
   - Switch to another account
   - Call `buyNFT(nftAddress, 0)` with value = 1000000000000000000 wei
6. Unlist:
   - List another token (e.g., 2), then call `cancelListing(nftAddress, 2)`
7. Inspect:
   - `getListing(nftAddress, tokenId)` to check listing state
   - `ownerOf(tokenId)` on SimpleNFT to verify transfers

## Notes and Potential Extensions

- Consider using `address(this).balance` checks and pull-payments if adding more complex flows.
- If supporting ERC‑2981 royalties, reconcile royalty settings against the standard.
- Add pausable functionality or marketplace-wide controls for maintenance.
- Use an indexer (e.g., The Graph) to build performant frontends using emitted events.
