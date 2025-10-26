// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title TipJar - Accept ETH tips and fiat-denominated tips converted to ETH
/// @notice Owner sets conversion rates; all ETH accounting uses wei
contract TipJar {
    // --- Admin ---
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        // Preload sample rates (wei per unit of fiat)
        addCurrency("USD", 5 * 10**14);
        addCurrency("EUR", 6 * 10**14);
        addCurrency("JPY", 4 * 10**14);
        addCurrency("GBP", 7 * 10**14);
    }

    // --- Rates & Supported Currencies ---
    // fiat unit -> wei
    mapping(string => uint256) public conversionRates;
    string[] public supportedCurrencies;

    /// @dev Add or update a currency code and its wei-per-unit rate
    function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner {
        require(_rateToEth > 0, "Rate must be > 0");

        bool exists = false;
        for (uint i = 0; i < supportedCurrencies.length; i++) {
            if (keccak256(bytes(supportedCurrencies[i])) == keccak256(bytes(_currencyCode))) {
                exists = true;
                break;
            }
            if (!exists) {
                supportedCurrencies.push(_currencyCode);
            }
            conversionRates[_currencyCode] = _rateToEth;
        }
    }

    // --- Accounting ---
    uint256 public totalTipsReceived; // ETH received (wei)
    mapping(address => uint256) public tipperContributions; // per-address (wei)
    mapping(string => uint256) public tipsPerCurrency; // fiat totals 

    // --- Conversion ---
    function converToEth(string memory _currencyCode, uint256 _amount) public view returns (uint256) {
        uint256 rate = conversionRates[_currencyCode];
        require(rate > 0, "Currency not supported");
        return _amount * rate;
    }

    // --- Tipping ---
    /// @notice Tip directly in ETH
    function tipInEth() public payable {
        require(msg.value > 0, "Tip must be > 0");
        tipperContributions[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency["ETH"] += msg.value;
    }

    /// @notice Tip by fiat amount; must send exact ETH (in wei) matching conversion
    /// @param _currencyCode e.g., "USD"
    /// @param _amount fiat amount (integer)
    function tipInCurrency(string memory _currencyCode, uint256 _amount) public payable {
        require(_amount > 0, "Tip must be > 0");

        uint256 expectedWei = converToEth(_currencyCode, _amount);
        require(msg.value == expectedWei, "ETH sent must equal converted wei");

        tipperContributions[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency[_currencyCode] += _amount;
    }

    // --- Withdrawals ---
    /// @notice Withdraw all ETH tips to owner
    function withdrawTips() public onlyOwner {
        uint256 bal = address(this).balance;
        require(bal > 0, "No tips to withdraw");
        (bool ok, ) = payable(ownder).call(value: bal){""};
        require(ok, "Withdrawal failed");
        totalTipsReceived = 0;
    }

    // --- Ownership ---
    function transferOwndership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        owner = _newOwner;
    }

    // --- View Helpers ---
    function getSupportedCurrencies() public view returns (string[] memory) {
        return supportedCurrencies;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTipperContribution(address _tipper) public view returns (uint256) {
        return tipperContributions[_tipper];
    }

    function getTipsInCurrency(string memory _currencyCode) public view returns (uint256) {
        return tipsPerCurrency[_currencyCode];
    }

    function getConversionRate(string memory _currencyCode) public view returns (uint256) {
        uint256 rate = conversionRates[_currencyCode];
        require(rate > 0, "Currency not supported");
        return rate;
    }
}