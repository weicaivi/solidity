`public` vs `external` 
1. Accessibility:
    - `public`: can be called both externally (by other contracts or externally owned accounts) and internally (by other functions within the same contract).
   - `external`: can only be called externally. They cannot be called internally from within the same contract using a direct call ( `functionName()`). However, they can be called internally using `this.functionName()`, which essentially performs an external call to the current contract.
2. Gas Efficiency (especially with array arguments):
    - `public`: When a public function is called, especially with array arguments, Solidity copies the arguments to memory. This is necessary because public functions can be called internally, and internal calls expect arguments to be in memory. Memory allocation is a gas-intensive operation.
    - `external`: external functions can read array arguments directly from calldata. calldata is a read-only, immutable area where function arguments are stored during an external call. Reading from calldata is generally cheaper than copying to memory, making external functions more gas-efficient when dealing with large array arguments, as they avoid the memory copy.
3. Use Cases and Best Practices:
    - Use `public` when a function needs to be callable both from outside the contract and by other functions within the same contract.
    - Use `external` when a function is intended to be called only from outside the contract and does not need to be invoked by other functions within the same contract. This is particularly beneficial for gas optimization when passing large arrays or complex data structures as arguments.

---

`payable` keyword

- marks a function or address as capable of receiving the network's native currency, like Ether. To send Ether to a contract, a function must be declared payable; otherwise, the transaction will revert. You can also declare an address payable to explicitly convert a regular address type to one that can receive Ether. 

---

