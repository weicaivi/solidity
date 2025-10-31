# Smart Calculator

A modular calculator in Solidity is a great way to separate concerns, keep code maintainable, and enable reuse. We’ll build two contracts—one for basic arithmetic and one for advanced operations—and wire them together with both high-level and low-level calls.

## Overview

- Calculator.sol: handles basic math (add, subtract, multiply, divide).
- ScientificCalculator.sol: handles advanced math (power, square root).
- Communication:
  - High-level typed calls (import and cast the address to the contract type).
  - Low-level ABI-encoded calls when you only know the address and function signature.

## Architecture

- Owner pattern: restrict linking of the ScientificCalculator to the contract deployer.
- Saved address: Calculator stores the deployed address of ScientificCalculator to route advanced requests.
- Pure vs. View:
  - Basic math functions are pure (no state reads/writes).
  - Power uses a view function in Calculator that reads the saved address and calls ScientificCalculator.
  - Square root example demonstrates a low-level call (could be nonpayable; shown here as state-free for clarity).

### Contract Map (Conceptual)

- User → Calculator
  - Local: add, subtract, multiply, divide
  - Delegated: power, squareRoot → ScientificCalculator
- Owner:
  - setScientificCalculator(address)

## Files

### ScientificCalculator.sol (advanced functions)

```solidity
// SPDX-License-Identifier: MIT  
pragma solidity ^0.8.0;

contract ScientificCalculator {
    // Exponentiation: base ** exponent
    function power(uint256 base, uint256 exponent) public pure returns (uint256) {
        if (exponent == 0) return 1;
        return base ** exponent;
    }

    // Integer square root approximation via Newton's Method
    function squareRoot(uint256 number) public pure returns (uint256) {
        // Solidity uint256 is always non-negative; retain guard for clarity
        if (number == 0) return 0;

        uint256 result = number / 2 + 1; // initial guess (avoid division by zero)
        uint256 prev;

        // Iterate until convergence or a reasonable cap
        for (uint256 i = 0; i < 50; i++) {
            prev = result;
            result = (result + number / result) / 2;
            if (result >= prev) break; // converged (monotonic non-increasing)
        }
        // Ensure floor behavior (result^2 <= number)
        while (result * result > number) {
            result--;
        }
        return result;
    }
}
```
Notes:
- power uses Solidity’s built-in exponent operator for integers.
- squareRoot returns the integer floor of the square root using Newton’s Method and guards for convergence and flooring.


### Calculator.sol (basic functions + wiring)
```solidity
// SPDX-License-Identifier: MIT  
pragma solidity ^0.8.0;

import "./ScientificCalculator.sol";

contract Calculator {
    address public owner;
    address public scientificCalculatorAddress;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    // Link the deployed ScientificCalculator contract
    function setScientificCalculator(address _address) public onlyOwner {
        require(_address != address(0), "Invalid address");
        scientificCalculatorAddress = _address;
    }

    // Basic math (pure)
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }

    function subtract(uint256 a, uint256 b) public pure returns (uint256) {
        return a - b;
    }

    function multiply(uint256 a, uint256 b) public pure returns (uint256) {
        return a * b;
    }

    function divide(uint256 a, uint256 b) public pure returns (uint256) {
        require(b != 0, "Cannot divide by zero");
        return a / b;
    }

    // High-level typed call to ScientificCalculator.power
    function calculatePower(uint256 base, uint256 exponent) public view returns (uint256) {
        require(scientificCalculatorAddress != address(0), "ScientificCalculator not set");
        ScientificCalculator sci = ScientificCalculator(scientificCalculatorAddress);
        return sci.power(base, exponent);
    }

    // Low-level ABI-encoded call to ScientificCalculator.squareRoot
    function calculateSquareRoot(uint256 number) public view returns (uint256) {
        require(scientificCalculatorAddress != address(0), "ScientificCalculator not set");

        // Encode function signature and argument
        bytes memory data = abi.encodeWithSignature("squareRoot(uint256)", number);

        // Perform low-level call
        (bool success, bytes memory returnData) = scientificCalculatorAddress.staticcall(data);
        require(success, "External call failed");

        // Decode return value
        return abi.decode(returnData, (uint256));
    }
}
```

Key points:
- setScientificCalculator is restricted to the owner and validates the address.
- calculatePower uses a typed contract reference (import + cast) for clarity and type safety.
- calculateSquareRoot shows how to use ABI encoding + low-level calls; staticcall is used for read-only safety.

## Why Split Contracts?

- Maintainability: Separate basic and advanced math concerns.
- Reusability: ScientificCalculator can be used elsewhere.
- Safety and clarity: Typed high-level calls catch errors at compile-time when you know the external contract’s interface.
- Flexibility: Low-level calls allow interaction when only an address and signature are known (riskier; add guards and decoding carefully).

## Implementation Tips

- Access control: Owner-only setter prevents malicious relinking to an unexpected contract.
- Gas and safety:
  - Prefer high-level calls when possible; they’re safer and clearer.
  - Use staticcall for read-only external calls to avoid accidental state changes.
  - Validate addresses and check call success.
- Integer math:
  - Solidity has no floating-point; design square root as an integer approximation (floor).
  - Watch for overflow in multiplications; consider SafeMath in earlier compiler versions (pre-0.8) or manual checks if needed (0.8+ has built-in overflow checks).




## Next Steps

- Extend ScientificCalculator with more functions (e.g., factorial, gcd, modular exponentiation).
- Replace low-level calls with interfaces when you know the ABI but don’t want to import full source.
- Add events when the owner updates the calculator address.
- Consider library patterns for math to minimize storage and enable reuse across contracts.

## ABI-encoded low-level calls

ABI-encoded low-level calls manually format function data to interact with contracts by address.

In Solidity, high-level calls like `other.power(x)` let the compiler generate the call data and type-check everything. Low-level calls flip that around: you craft the call data yourself using the contract’s ABI, then send it to an address using `call`, `staticcall`, or `delegatecall`. This is useful when you only know an address and function signature, or want more control over error handling.

What “ABI encoding” means

- The ABI (Application Binary Interface) defines how to turn a function name and arguments into bytes the EVM understands:
  - Function selector: first 4 bytes of `keccak256(“functionName(type1,type2,…)”)`
  - Arguments: each encoded in 32-byte words per ABI rules (uint256, address, bytes, etc.)

Solidity helpers do this for you:
- `abi.encodeWithSignature(“squareRoot(uint256)”, number)` → selector + encoded args
- `abi.encodeWithSelector(0x12345678, arg1, arg2)` → use a precomputed selector
- `abi.encode(arg1, arg2, …)` → just arguments, no selector

Making the low-level call
- `call`: can modify state; returns (success, returnData)
- `staticcall`: read-only; safer for pure/view functions
- `delegatecall`: runs code of target in caller’s context; used for proxies, not typical here


Common pitfalls and fixes
- Wrong signature string: types must match exactly (“uint256” vs “int256” will fail).
- Unset or wrong address: check scientificCalculatorAddress != address(0).
- Using call instead of staticcall for view/pure functions: prefer staticcall to prevent unintended state changes.
- Decoding wrong type: abi.decode must match the function’s return type.
- Reverts without reason: ok will be false; consider bubbling up the revert reason by parsing ret if needed.


When to prefer interfaces over low-level calls

- If you know the external contract’s function signatures, define an interface and use typed calls. You get compile-time safety and clearer code:
    ```solidity
    interface ISci {
        function squareRoot(uint256 number) external pure returns (uint256);
    }
    ISci sci = ISci(scientificCalculatorAddress);
    uint256 r = sci.squareRoot(27);
    ```
    Low-level calls are best when you lack source/ABI, need dynamic selectors, or are building proxy patterns.

Debugging tips
- Compute and log the selector to verify: `bytes4(keccak256(“squareRoot(uint256)”))`
- Check gas usage and returnData length; zero-length often means revert.
- Add require(ok, “…”) guards and fallbacks if the target upgrades or changes ABI.

Security considerations
- Trust the address you call; a malicious contract can revert or consume gas.
- Validate inputs before encoding to avoid unexpected overflows or divide-by-zero in the callee.
- Avoid delegatecall unless you understand proxy risks; it changes storage in the caller.