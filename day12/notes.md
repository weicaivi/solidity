# Minimal ERC‑20 Token
standardizing token behavior for ecosystem compatibility

## Overview
let’s create an ERC‑20 token so it works seamlessly with wallets, DApps, and exchanges.

This guide explains:
- Why ERC‑20 exists
- The required interface (names, balances, transfers, approvals, events)
- A minimal token contract
- What’s intentionally missing
- How to use OpenZeppelin for production

## Why ERC‑20?
Early Ethereum tokens were inconsistent: different function names, missing balance checks, and no events. Wallets and exchanges had to add custom logic for each token.

ERC‑20 standardized the interface so tokens are:
- Interoperable and “plug‑and‑play”
- Instantly compatible with wallets (e.g., MetaMask), DEXs, DAOs, lending protocols

## What ERC‑20 Defines
A consistent interface including:

- Naming and Display
  - `name`, `symbol`, `decimals` so wallets show tokens correctly.
- Supply and Balances
  - `totalSupply()` and `balanceOf(address)`.
- Transfers
  - `transfer()` sends tokens from the caller to another address.
- Approvals and Delegated Spending
  - `approve()` grants spending permission to a spender.
  - `transferFrom()` performs approved transfers.
- Events
  - `Transfer` and `Approval` events so tools can track on‑chain activity.

## Minimal ERC‑20 Contract
A stripped‑down implementation for learning. It omits mint/burn, advanced safety checks, and access control.

SimpleERC20.sol:
```solidity
// SPDX-License-Identifier: MIT
pragma solidity^0.8.20;

contract SimpleERC20 {
    string public name = "SimpleToken";
    string public symbol = "SIM";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance; 
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(uint256 _initialSupply) {
        totalSupply = _initialSupply * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address_ to, uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Not enough balance");
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns(bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        require(balanceOf[_from] >= _value, "Not enough balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance too low");
        
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Invalid address");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emitTransfer(_from, _to, _value);
    }
}
```
### Key Parts Explained

- Token Metadata
  - `name`, `symbol`, `decimals`
  - Most tokens use 18 decimals (ETH style) for precision.

- Total Supply
  - `totalSupply` stores how many tokens exist.

- Balances and Allowances
  - `balanceOf[address]` shows holdings.
  - `allowance[owner][spender]` sets how much a spender may use on behalf of the owner.

- Events
  - `Transfer(from, to, value)` fires on token movement.
  - `Approval(owner, spender, value)` fires when permissions change.
  - `indexed` parameters make event filtering efficient in logs.

- Constructor: Initial Mint
  - Scales by decimals: `initialSupply * 10 ** decimals`.
  - Assigns the entire supply to `msg.sender`.
  - Emits a mint‑style `Transfer` from `address(0)`.

- transfer()
  - Checks sender balance, then delegates to `_transfer()` for actual balance updates.

- _transfer() (internal)
  - Prevents sending to `address(0)` (which would burn).
  - Updates balances and emits `Transfer`.
  - Centralizes balance logic to keep code DRY and consistent.

- transferFrom()
  - Checks owner balance and caller allowance.
  - Decreases allowance, calls `_transfer()` to move tokens.
  - Enables DEX, DAO, and other contract‑driven operations.

- approve()
  - Sets `allowance[owner][spender] = value` and emits `Approval`.
  - Grants permission; actual movement happens via `transferFrom()`.

## What’s Missing (By Design)
This minimal contract is for learning. For real deployments, you’ll need:

- Safer Approvals
  - Front‑running risk with `approve()`. Prefer `increaseAllowance()` / `decreaseAllowance()` patterns.

- Minting/Burning
  - No way to change supply after deployment.

- Access Control/Ownership
  - No roles for minting, pausing, or admin actions.

- Pausable/Circuit Breakers
  - No emergency stop if a bug/exploit occurs.

- Upgradability
  - Logic cannot be upgraded without redeploying.

## Production‑Ready: Use OpenZeppelin
OpenZeppelin provides audited, modular ERC‑20 implementations and extensions.

Example:
```solidity
// SPDX-License-Identifier: MIT
pragma solidity^0.8.20;

import"@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyTokenisERC20 {
    constructor(uint256 initialSupply) ERC20("MyToken", "MTK") {
        _mint(msg.sender, initialSupply * 10 ** decimals());
    }
}
```

Helpful extensions:
- `ERC20Burnable` (holders can burn)
- `ERC20Pausable` (pause transfers on emergencies)
- `Ownable` or `AccessControl` (admin roles)
- `ERC20Permit` (gasless approvals via signatures)
