# PreorderTokens — A Simple ERC‑20 Presale Contract

Build a minimal, production‑style token presale (ICO) on top of your ERC‑20. Buyers send ETH at a fixed price, receive tokens automatically, transfers are locked during the sale, and the owner finalizes to claim funds.

## What You’ll Implement
- Fixed‑price sale in ETH for your custom ERC‑20 token
- Start/end timestamps for the sale window
- Minimum and maximum purchase limits (per transaction)
- Automatic token distribution from the sale contract
- Transfer locks during the sale to prevent flipping/bot dumping
- Finalization step that sends all raised ETH to the project owner
- Helper views for time remaining and tokens available
- Seamless purchasing via `receive()` when ETH is sent directly

## Preparation: Mark Functions as Overridable
To restrict transfers during the sale, the sale contract must override ERC‑20 transfer functions. In your `SimpleERC20` parent contract, mark these as `virtual`:
- `transfer(address _to, uint256 _value) public virtual returns (bool);`
- `transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool);`

This allows a child contract to customize transfer behavior during the presale.

## Contract Overview: `SimplifiedTokenSale` (inherits `SimpleERC20`)
The sale contract extends your ERC‑20 and adds presale logic. It mints the initial supply via the parent constructor, then moves all tokens into itself to act as the distributor.

### State Variables
- `tokenPrice` (uint256): Price per token in wei (1 ETH = 10^18 wei).
- `saleStartTime`, `saleEndTime` (uint256): Unix timestamps for sale start/end.
- `minPurchase`, `maxPurchase` (uint256): Per‑transaction ETH limits (in wei).
- `totalRaised` (uint256): Cumulative ETH collected.
- `projectOwner` (address): Destination of raised ETH after finalization.
- `finalized` (bool): Whether the sale is closed and transfers unlocked.
- `initialTransferDone` (bool): Marks that the initial supply moved to the sale contract.

### Events
- `TokensPurchased(address indexed buyer, uint256 etherAmount, uint256 tokenAmount)`: Logs purchases for frontends/explorers.
- `SaleFinalized(uint256 totalRaised, uint256 totalTokensSold)`: Signals completion with final metrics.

### Constructor (Setup)
- Calls `SimpleERC20(_initialSupply)` to mint and assign supply to the deployer.
- Sets `tokenPrice`, `saleStartTime = block.timestamp`, `saleEndTime = block.timestamp + _saleDurationInSeconds`.
- Configures `minPurchase`, `maxPurchase`, and `projectOwner`.
- Transfers the entire supply from the deployer to the sale contract via `_transfer(msg.sender, address(this), totalSupply)`.
- Sets `initialTransferDone = true` to enable transfer locking logic safely.

### Sale Status Helper
- `isSaleActive() -> bool`: True if not finalized and current time is within `[saleStartTime, saleEndTime]`.

### Buying Flow
`buyTokens()` (payable):
1. Validates the sale window: `require(isSaleActive(), "Sale is not active")`.
2. Enforces ETH bounds: `require(msg.value >= minPurchase, ...)` and `require(msg.value <= maxPurchase, ...)`.
3. Computes token amount: `tokenAmount = (msg.value * 10**decimals) / tokenPrice`.
4. Confirms inventory: `require(balanceOf[address(this)] >= tokenAmount, ...)`.
5. Updates `totalRaised += msg.value`.
6. Sends tokens: `_transfer(address(this), msg.sender, tokenAmount)`.
7. Emits `TokensPurchased`.

### Transfer Locks (Overrides)
To prevent trading during the sale, override ERC‑20 transfers:

- `transfer(...)`:
  - If the sale is not finalized, the sender is not the contract itself, and initial tokens were moved, revert with `"Tokens are locked until sale is finalized"`.
  - Otherwise, call `super.transfer(...)`.

- `transferFrom(...)`:
  - If the sale is not finalized and the source `_from` is not the contract, revert similarly.
  - Otherwise, call `super.transferFrom(...)`.

This blocks both direct and delegated transfers (including via approved spenders like AMMs) until the sale is finalized, preventing early flipping/manipulation.

### Finalization
`finalizeSale()`:
- Access control: only `projectOwner` can call.
- Requires the sale period has ended and not already finalized.
- Sets `finalized = true` to unlock transfers.
- Computes `tokensSold = totalSupply - balanceOf[address(this)]`.
- Sends all ETH to `projectOwner` using a low‑level call: `(bool success, ) = projectOwner.call{ value: address(this).balance }(""); require(success, ...)`.
- Emits `SaleFinalized(totalRaised, tokensSold)`.

### View Helpers (Frontend/Dashboard)
- `timeRemaining() -> uint256`:
  - Returns seconds until `saleEndTime` (or `0` if ended).
- `tokensAvailable() -> uint256`:
  - Returns `balanceOf[address(this)]` (remaining inventory).

Both are `view` functions — free to read off‑chain and ideal for UX elements like countdowns and remaining supply indicators.

### Seamless ETH Purchases
`receive() external payable`:
- Automatically routes direct ETH transfers to `buyTokens()` for a smooth user experience.
- Users can participate by simply sending ETH to the contract address; no UI or manual function call needed.

## Design Rationale (Quick Notes)
- Locking transfers ensures fairness and discourages early speculation and bot dumping.
- Min/max purchase limits reduce spam and single‑tx whale buys.
- Finalization separates sale logic from post‑sale token mobility and owner fund collection.
- Helper views keep integration simple for dApps and explorers.
- Using `.call{value: ...}` for ETH transfer avoids `transfer()`’s gas‑stipend pitfalls.

## Implementation Tips
- Choose a `tokenPrice` that aligns with your decimals; typical ERC‑20s use `decimals = 18`.
- Express `minPurchase` and `maxPurchase` in wei, e.g., `minPurchase = 0.05 ether`, `maxPurchase = 5 ether`.
- Consider pausing `receive()` after sale ends if you don’t want post‑sale accidental sends.
- Add input validation in the constructor (e.g., `saleDuration > 0`, `minPurchase <= maxPurchase`, `projectOwner != address(0)`).
- If you later add vesting or whitelist logic, keep overrides consistent to maintain transfer safety during sale periods.

## Example Usage Flow
1. Deploy `SimplifiedTokenSale` with parameters:
   - `_initialSupply`, `_tokenPrice`, `_saleDurationInSeconds`, `_minPurchase`, `_maxPurchase`, `_projectOwner`.
2. Buyers call `buyTokens()` with ETH or send ETH directly to the contract.
3. During the sale, transfers are locked except internal sends from the contract itself.
4. After `saleEndTime`, `projectOwner` calls `finalizeSale()` to unlock transfers and claim ETH.
5. Post‑sale, tokens move freely via standard ERC‑20 transfers.