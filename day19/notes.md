# SignThis: Off-Chain Signature Verification for Private Web3 Events

A lightweight, gas-efficient access system for token‑gated events. Instead of storing a whitelist on-chain, the organizer signs off-chain invites; attendees present their signature at check-in; the contract verifies the signature on-chain.

## Why This Pattern
- No on-chain whitelist storage
- Gas-efficient verification
- Fully verifiable on-chain access
- Flexible backends and unlimited invite capacity

## Core Concepts
- Message hashing: keccak256 over contextual data such as contract address, event name, and attendee address
- Ethereum signed message prefix (EIP-191 personal_sign format)
- Signature components: v, r, s (ECDSA)
- Signer recovery on-chain with ecrecover

## Contract Overview (EventEntry)
State
- eventName: string
- organizer: address
- eventDate: uint256 (Unix timestamp)
- maxAttendees: uint256
- attendeeCount: uint256
- isEventActive: bool
- hasAttended: mapping(address => bool)

Events
- EventCreated(name, date, maxAttendees)
- AttendeeCheckedIn(attendee, timestamp)
- EventStatusChanged(isActive)

Constructor
- Sets event metadata
- Organizer is deployer (msg.sender)
- Makes event active; emits EventCreated

Access Control
- onlyOrganizer modifier: organizer-only changes
- setEventStatus(bool): toggle accept‑check‑ins; emits EventStatusChanged

Message + Signature Flow
- getMessageHash(attendee): keccak256(abi.encodePacked(address(this), eventName, attendee))
- getEthSignedMessageHash(messageHash): keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash))
- recoverSigner(ethSignedMessageHash, signature): parses (v,r,s), normalizes v to 27/28, returns ecrecover(...)
- verifySignature(attendee, signature): returns recoverSigner(...) == organizer

Check-In
- Validates: event active, within window (<= eventDate + 1 days), not already attended, capacity not exceeded, signature valid
- Marks attendance and emits AttendeeCheckedIn

## Organizers & Attendees: User Path
Organizer
1) Deploy contract with eventName, eventDate (Unix), and maxAttendees
2) Generate message hash per attendee: getMessageHash(attendee)
3) Sign hash off-chain (personal_sign / eth_sign compatible) and deliver signature to attendee
4) Optionally pause/resume via setEventStatus

Attendee
1) Receive signature from organizer
2) Call checkIn(signature) from their address
3) Confirm attendance via hasAttended(attendee) and watch AttendeeCheckedIn

## Frontend/Backend Signing Example (ethers.js)
```js
import { ethers } from "ethers";

async function generateSignature(organizerWallet, attendee, contractAddress, eventName) {
  const messageHash = ethers.utils.solidityKeccak256(
    ["address","string","address"],
    [contractAddress, eventName, attendee]
  );
  const signature = await organizerWallet.signMessage(ethers.utils.arrayify(messageHash));
  return signature; // 65-byte hex (r|s|v)
}
```

## Remix Quickstart
1) Deploy: eventName = "Web3 Summit", eventDate = now + 86400, maxAttendees = 100
2) getMessageHash(attendeeAddress)
3) Sign off-chain with organizer key (personal_sign / signMessage)
4) Attendee calls checkIn(signature)

## Gas & Security Notes
- Storage-free whitelist: verification is ~3–5k gas + call data; avoid 20k+ per address storage
- Add anti-replay: include nonce and deadline in your message; track nonces on-chain
- Bind context: include contract address, chainId, event name (or an eventId)
- Signature format: ensure the same hash and prefix are used both off-chain and on-chain
- Consider EIP‑712 (typed data) for clearer UX and stronger replay protection

## EIP‑712 Upgrade (optional pattern)
Replace personal_sign with typed structured data:
- Domain: name/version/chainId/verifyingContract
- Struct: AttendeeInvite(attendee, eventId, nonce, deadline)
- Digest: keccak256("\x19\x01", DOMAIN_SEPARATOR, structHash)
- Recover signer via ecrecover; require signer == organizer; consume nonce; check deadline

## Batch Check-In (optional extension)
For larger events, a loop over arrays of attendees + signatures can process many check-ins in one call. Validate each signature; skip already-attended; bound total to capacity.

## Troubleshooting
- “Invalid signature”: mismatch in hashing inputs or prefix; check ordering and types
- v normalization: convert 0/1 to 27/28 before ecrecover
- Different wallets: ensure they use the same signing method (personal_sign vs eth_sign)
- Past event window: check eventDate + 1 days logic and timezones

## Glossary
- ECDSA: Elliptic curve digital signatures used by Ethereum
- v, r, s: Signature components; v is recovery id; r/s are curve parameters
- ecrecover: EVM precompile to recover signer from digest + signature
- EIP‑191: Signed message prefix standard (personal_sign)
- EIP‑712: Typed structured data signing standard