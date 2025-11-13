# Decentralized Lottery with Chainlink VRF (V2.5)

A hands-on guide to building a provably fair, automated, and tamper‑resistant on‑chain lottery using Chainlink VRF.

## Why randomness matters
- Smart contracts are deterministic and can’t safely generate randomness by themselves.
- Block data like timestamps and blockhashes are biasable or miner‑influenced.
- Chainlink VRF provides verifiable randomness and an on‑chain proof that prevents manipulation.

## What we’ll build
A lottery that:
- Is provably fair and automated
- Uses Chainlink VRF to pick a random winner
- Holds all entry fees and pays the winner on-chain

Core properties:
- States: OPEN → CALCULATING → CLOSED
- Only the owner can start/end rounds
- Players enter by paying an entry fee
- VRF callback selects a winner and transfers the pot

## Contract outline

### Key dependencies
- Inherit VRFConsumerBaseV2Plus
- Use VRFV2PlusClient to create randomness requests

### State and roles
- LOTTERY_STATE enum: OPEN, CLOSED, CALCULATING
- players: address payable[] for current round
- recentWinner: last round’s winner
- entryFee: minimum ETH to enter
- VRF config:
  - subscriptionId
  - keyHash (VRF job identifier)
  - callbackGasLimit (e.g., 100,000)
  - requestConfirmations (e.g., 3)
  - numWords (e.g., 1)
- latestRequestId: track the last randomness request
- Owner: controls start/end of lottery

### Lifecycle
1) Deploy and initialize with VRF settings and an entry fee.
2) Owner calls startLottery() → state OPEN.
3) Players call enter() with ≥ entryFee.
4) Owner calls endLottery() → state CALCULATING and requests randomness.
5) Chainlink VRF calls fulfillRandomWords() → pick winner, transfer balance, reset, state CLOSED.

### Core functions
- constructor(vrfCoordinator, subscriptionId, keyHash, entryFee)
- enter(): payable, requires OPEN and enough ETH
- startLottery(): onlyOwner, requires CLOSED → set to OPEN
- endLottery(): onlyOwner, requires OPEN → set to CALCULATING; request VRF randomness
- fulfillRandomWords(requestId, randomWords): internal override; verify state; compute winnerIndex = randomWords[0] % players.length; transfer funds; reset
- getPlayers(): view helper for frontend

## Reference implementation (VRF v2.5)

Note: This is a streamlined example. Ensure you import onlyOwner (e.g., via Ownable) if not provided by your base class, and confirm network‑specific addresses in Chainlink docs.


## Reconciling small inconsistencies
- Owner modifier: Ensure your contract imports and uses a proper onlyOwner (e.g., OpenZeppelin Ownable). Some variants assume inheritance that doesn’t include owner controls.
- Resetting players: Use `delete players;` or `players = new address payable[](0);` — both clear the array; prefer `delete players` for clarity.
- VRF extraArgs (nativePayment): The Chinese tutorial uses nativePayment: true; verify funding method (subscription vs direct/native) per network and billing preference.
- Callback signature: Use `uint256[] calldata randomWords` for V2.5 implementations (as in Chainlink examples).
- Safety: Require `players.length > 0` before requesting randomness to avoid modulo by zero.

## Deployment (example: Base Sepolia)
- Network RPC: https://sepolia.base.org
- Explorer: https://sepolia.basescan.org
- Coordinator address and keyHash: confirm in Chainlink “Supported Networks” for VRF v2.5.
- Steps:
  1) Create and fund a VRF subscription (LINK or native, per v2.5 billing).
  2) Deploy the contract with vrfCoordinator, subscriptionId, keyHash, entryFee.
  3) Add the deployed contract as a Consumer to your VRF subscription.
  4) Start a round (startLottery), have players enter, then endLottery to request randomness.
  5) Wait for VRF callback; read recentWinner.

## Best practices
- Don’t accept entries during CALCULATING.
- Set reasonable callbackGasLimit (bench test your logic).
- Choose requestConfirmations that balance latency and security (e.g., 3).
- Consider pausing the lottery or refund flows on unexpected failures.
- Avoid relying on on-chain block data for randomness; use VRF for fair selection.

## Use cases beyond lotteries
- Game loot tables and card shuffles
- Randomized NFT traits/rarities
- Jury/committee member selection in DAOs
- Mystery boxes and raffles

## Security notes
- Reentrancy: Prize transfer uses call; reset state before transfer and consider nonReentrant if you expand logic.
- Access control: Guard start/end with onlyOwner and consider further role separation for production systems.
- Auditing: Treat the contract as educational until reviewed and audited.