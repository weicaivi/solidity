//SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

contract ClickCounter {

    uint256 public counter;

    function click() public 
    {
        counter++;
    }
}
