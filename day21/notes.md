# SimpleNFT: A Minimal ERC‑721 implementation

A concise guide to understanding NFTs, the ERC‑721 standard, and implementing a clean, dependency‑free NFT contract in Solidity. Includes practical steps for minting and viewing your NFT using IPFS and Remix.

## 1) NFTs in Plain English

- NFT = Non‑Fungible Token: a unique, non‑interchangeable digital asset.
- Unlike ERC‑20 (fungible) tokens, each NFT has its own ID and metadata; you can’t swap them 1:1.
- Beyond art, NFTs can represent tickets, in‑game items, credentials, deeds, and more. They bring verifiable digital ownership that is public, permanent, and programmable.

## 2) What ERC‑721 Defines

ERC‑721 is the interface that NFT contracts implement so wallets, dApps, and marketplaces can interact consistently.

Core functions:

- `balanceOf(address owner)`: count of NFTs owned by `owner`.
- `ownerOf(uint256 tokenId)`: owner of a given `tokenId`.
- `approve(address to, uint256 tokenId)`: grant `to` permission to transfer this `tokenId`.
- `getApproved(uint256 tokenId)`: check who is approved for this `tokenId`.
- `setApprovalForAll(address operator, bool approved)`: allow/revoke `operator` to manage all NFTs of the caller.
- `isApprovedForAll(address owner, address operator)`: query operator-wide approval.
- `transferFrom(address from, address to, uint256 tokenId)`: transfer without safety checks.
- `safeTransferFrom(address from, address to, uint256 tokenId[, bytes data])`: transfer with a check that `to` can receive ERC‑721 (preferred).

Events:

- `Transfer(from, to, tokenId)`: emitted on mint, burn, and transfer.
- `Approval(owner, approved, tokenId)`
- `ApprovalForAll(owner, operator, approved)`

Receiver interface:

- Contracts that wish to receive NFTs safely implement `IERC721Receiver.onERC721Received(...)`.

## 3) The Minimal Contract: Design Overview

Goals:

- No external libraries; just Solidity.
- Clear responsibilities:
  - Public functions: validate permissions and inputs.
  - Internal functions: move tokens and update state.
  - Helper checks: keep authorization logic reusable.

State:

- `name`, `symbol`: collection identity.
- `_tokenIdCounter`: sequential IDs, starting at 1 for human readability.
- `_owners[tokenId]`: who owns each token.
- `_balances[owner]`: how many tokens an address owns.
- `_tokenApprovals[tokenId]`: per‑token approved address.
- `_operatorApprovals[owner][operator]`: operator‑wide approval.
- `_tokenURIs[tokenId]`: metadata URI (e.g., IPFS CID).

Key flows:

- Mint: allocate a new `tokenId`, set owner, record URI, emit `Transfer(0x0, to, tokenId)`.
- Approvals: owner or authorized operator can set per‑token or operator‑wide approvals.
- Transfer:
  - `transferFrom`: requires `_isApprovedOrOwner(msg.sender, tokenId)`, then `_transfer`.
  - `safeTransferFrom`: same permission check, then `_safeTransfer` which ensures the recipient contract supports ERC‑721.
- `tokenURI(tokenId)`: returns the metadata URI; reverts if token doesn’t exist.

## 4) How to Deploy and Mint (Remix + IPFS)

Prerequisites:

- MetaMask with test ETH (e.g., Sepolia).
- Remix IDE (browser).
- An IPFS pinning service (e.g., Pinata) to host images and metadata.

Steps:

1. Deploy

- Open Remix, create `SimpleNFT.sol`, paste the contract.
- Set compiler to `0.8.19`. Compile.
- In “Deploy & Run Transactions,” choose “Injected Provider – MetaMask,” connect your wallet.
- Deploy with a collection name and symbol (e.g., “CryptoDragons”, “CDR”).

2. Upload image to IPFS

- Pinata: upload `dragon.png`, copy the CID.
- Preview via a gateway (optional): `https://gateway.pinata.cloud/ipfs/<CID>`.

3. Create metadata JSON

```json
{
  "name": "Dragon #1",
  "description": "A fierce fire-breathing NFT dragon.",
  "image": "ipfs://<image-CID>"
}
```

- Upload JSON to IPFS, copy the JSON CID.
- Token URI becomes `ipfs://<json-CID>`.

4. Mint via Remix

- Call `mint(to, uri)`:
  - `to`: your wallet address.
  - `uri`: `ipfs://<json-CID>`.
- Confirm the transaction. You’ve minted your NFT.

5. View your NFT

- Use the contract address on a testnet explorer.
- Marketplaces (testnets) can read `tokenURI`, fetch metadata, and display your NFT.

## 5) Practical Notes

- Always prefer `safeTransferFrom` to avoid sending NFTs to contracts that can’t receive them.
- Emitting `Transfer(address(0), to, tokenId)` on mint is required by the ERC‑721 event semantics.
- Start IDs at 1 (human friendly), though 0 is valid; the tutorial uses 1 for clarity.
- This minimal contract returns per‑token URIs via `tokenURI` without additional features like burns, enumerable indexes, royalties, or access control. Add those as needed.
- Avoid transfers or mints to the zero address; those are correctly guarded in this implementation.
- Metadata should be a valid JSON object that marketplaces expect; IPFS URIs (`ipfs://`) are recommended for decentralization.

## 6) Where to Go Next

- Add role‑based access control (e.g., owner‑only mint) if your project needs mint restrictions.
- Consider OpenZeppelin for production‑grade features (safe math, hooks, URI storage, enumeration, EIP‑165 support).
- Explore on‑chain metadata (for small SVGs) or Arweave for permanent storage.
- Implement `supportsInterface(bytes4)` (EIP‑165) for stricter standard compliance if integrating broadly.
