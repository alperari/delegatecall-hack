# Introduction

- You are given a smart contract **WithdrawalVault** which is basically works like a vault.

![withdrawalvault](https://user-images.githubusercontent.com/68128434/213879851-d180f708-b3ca-4406-8597-2daceb4a5502.png)

- You can withdraw money from that vault after you deploy it with some ETH.

- Also the vault uses another contract called **NumberLib** (For basic arithmetic operations).

<img src="https://user-images.githubusercontent.com/68128434/213879856-aabe70df-c40a-40a5-9546-dc638871bcc3.png" width="500">

## GOAL: Steal All Money From WithdrawalVault

- This is done by exploiting [vulnerability of delegatecall(): Storage Collision](https://solidity-by-example.org/hacks/delegatecall/) from another Attack contract.
- This Attack contract will have the same storage layout as vault.
- Plus, it will have several additional functions. These are:

```solidity
attack()                //Main function that performs the attack
setBase(uint offset)    //Same function in NumberLib
getNumber(uint offset)  //Same function in NumberLib
collect()               //To transfer money from Attack contract to your personal account, right after steal
receive()               //Needed since there will be inter-contract money transfer
```

### **So what `attack()` function does is basically as follows:**

**1.** It calls vault's `setBase(address of Attack contract)`
**2.** This will trigger vault's `fallback()`
**3**. Due to Attack contract having the same storage layout as vault, the very first element of vault (which is `numberLibrary`) will be replaced with the address of Attack contract
**4.** From now on, Attack contract can act as if its the `numberLibrary` of the vault
**5**. Then it calls vault's `setBase(<anything>)`
**6.** This will trigger vault's `fallback()` again
**7.** Since our Attack contract was acting as if it is vault's `numberLibrary`, vault's triggered `fallback()` will call Attack's `setBase()`
**8.** This will set `owner = address(Attack contract)`
**9.** After taking over the ownership of vault, `attack()` will call `withdraw()` function of victim. But this won't transfer any money to Attack contract because of `currentNumber` being zero
**10.** Nevertheless, Attack contract also had custom `getNumber()` function. So `withdraw()` function will call `getNumber()` of Attack contract. This custom function will transfer all money from vault to Attack contract (`receive()` function works here)

In the end, you can transfer all money from Attack contract to your personal address by calling `collect()`.

## REMIX Demo

![image](https://user-images.githubusercontent.com/68128434/213881632-203c0b5a-9d05-4149-bafd-fd5c33d1bdee.png)
![image](https://user-images.githubusercontent.com/68128434/213881646-9d5bf112-7414-4ee1-9593-530104f5f096.png)
![image](https://user-images.githubusercontent.com/68128434/213881659-2a97f928-17a0-41ef-b23c-dd0231ac5f0f.png)
![image](https://user-images.githubusercontent.com/68128434/213881672-e02bcc05-ac4f-47bb-9fb8-17b25bf83803.png)
![image](https://user-images.githubusercontent.com/68128434/213881678-66230ebe-d2b9-4d0d-8e6b-1600b74f6f2b.png)
