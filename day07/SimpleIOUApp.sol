//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract simpleIOU {
    address public owner;
    address[] public friendList;
    mapping(address => bool) public registeredFriends;
    mapping(address => uint256) public balances;
    // debtor -> {creditor -> amount}
    mapping(address => mapping(address => uint256)) public debts;

    constructor() {
        owner = msg.sender;
        friendList.push(msg.sender);
        registeredFriends[msg.sender] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyRegistered() {
        require(registeredFriends[msg.sender], "You are not registered");
        _;
    }

    function addFriend(address _friend) public onlyOwner {
        require(_friend != address(0), "Invalid address");
        require(!registeredFriends[_friend], "Friend already registered");

        friendList.push(_friend);
        registeredFriends[_friend] = true;
    }

    // deposit funds to your balance
    function depositIntoWallet() public payable onlyRegistered {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
    }

    function recordDebt(address _debtor, uint256 _amount) public onlyRegistered {
        require(_debtor != address(0), "Invalid debtor address");
        require(registeredFriends[_debtor], "Debtor address not registered");
        require(_amount > 0,  "Amount must be greater than 0");

        debts[_debtor][msg.sender] += _amount;
    }

    // pay off debt using internal balance transfer
    function payFromWallet(address _creditor, uint256 _amount) public payable onlyRegistered {
        require(_creditor != address(0), "Invalid creditor address");
        require(registeredFriends[_creditor], "Creditor address not registered");
        require(_amount > 0,  "Amount must be greater than 0");
        require(debts[msg.sender][_creditor] >= _amount, "Debt amount incorrect");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        balances[_creditor] += _amount;
        debts[msg.sender][_creditor] -= _amount;
    }

    // direct transfer method using transfer()
    function transferEther(address payable _to, uint256 _amount) public onlyRegistered {
        require(_to != address(0), "Invalid creditor address");
        require(registeredFriends[_to], "recipient address not registered");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        _to.transfer(_amount);
        balances[_to] += _amount;
    }

    // alternative transfer method using call()
    function transferEtherViaCall(address payable _to, uint256 _amount) public onlyRegistered {
        require(_to != address(0), "Invalid creditor address");
        require(registeredFriends[_to], "recipient address not registered");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        (bool success, ) = _to.call{value: _amount}("");
        balances[_to] += _amount;
        require(success, "Transfer failed");
    }

    function withdraw(uint256 _amount) public onlyRegistered {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] -= _amount;
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawl failed");
    }

    function checkBalance() public view onlyRegistered returns (uint256) {
        return balances[msg.sender];
    }
}

