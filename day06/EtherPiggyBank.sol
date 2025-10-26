// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherPiggyBank {
    // roles and membership
    address public bankManager;
    address[] private members;
    mapping(address => bool) public registeredMembers;

    // balances (simulation units OR wei for ETH deposits)
    mapping(address => uint256) private balance;

    // simple reentrancy guard for future ETH withdrawals
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "Reentrancy");
        _locked = true;
        _;
        _locked = false;
    }

    constructor() {
        bankManager = msg.sender;
        members.push(msg.sender);
        registeredMembers[msg.sender] = true;
    }

    modifier onlyBankManager() {
        require(msg.sender == bankManager, "Only bank manager");
        _;
    }

    modifier onlyRegisteredMember() {
        require(registeredMembers[msg.sender], "Not a registered member");
        _;
    }

    // Admin: Add members
    function addMembers(address _member) public onlyBankManager {
        require(_member != address(0), "Invalid address");
        require(_member != msg.sender, "Manager already a memver");
        require(!registeredMembers[_member], "Already registered");
        members.push(_member);
        registeredMembers[_member] = true;
    }

    // View: Members list
    function getMembers() public view returns (address[] memory) {
        return members;
    }

    // simulation deposit (no ETH, just accounting)
    function deposit(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0, "Amount must be > 0");
        balance[msg.sender] += _amount;
    }

    // simulation withdraw (no ETH transfer)
    function withdraw(uint256 _amount) public onlyRegisteredMember {
        require(_amount > 0, "Amount must be > 0");
        require(balance[msg.sender] >= amount, "Insufficient balance");
        balance[msg.sender] -= _amount;
    }

    // real Ether deposit
    function depositAmountEther() public payable onlyRegisteredMember {
        require(msg.value > 0, "Amount must be > 0");
        balance[msg.sender] += msg.value;
        // Ether stays in contract; balance tracks per-user deposits in wei
    }

    // real Ether withdraw (enable when ready)
    function withdrawEther(uint256 amountWei) public onlyRegisteredMember nonReentrant {
        require(amountWei > 0, "Amount must be > 0");
        require(balance[msg.sender] >= amountWei, "Insufficient balance");
        

        // checks effects interactions
        balance[msg.sender] -= amountWei;

       (bool ok, ) = msg.sender.call{value: amountWei}("");
       require(ok, "transfer failed");
    }

    // Views
    function getMyBalance() external view onlyRegisteredMember returns (uint256) {
        return balance[msg.sender];
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

}
