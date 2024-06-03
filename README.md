
## G-Naira (gNGN) Smart Contract Documentation

## Overview

**The G-Naira (gNGN) smart contract is designed to create a digital currency for the country’s financial system, leveraging blockchain technologies for better transparency and accountability. This contract adheres to the ERC20 standard and includes additional functionalities for minting, burning, blacklisting addresses, and implementing multi-signature approval for critical actions**.

## Features

- **Compliance with ERC20 standard**.
- **Minting of new tokens**.
- **Burning of tokens**.
- **Blacklisting addresses to prevent them from sending and receiving tokens**.
- **A 'GOVERNOR' role that controls minting, burning, and blacklisting**.
- **Multi-signature wallet functionality for enhanced security**.

## Contract Details

**License**
**solidity**
**// SPDX-License-Identifier: UNLICENSED**

**pragma solidity ^0.8.25**;

## State Variables

- **confirmations: Tracks confirmations from owners**.
- **isOwner: Maps owner addresses**.
- **blacklisted: Tracks blacklisted addresses**.
- **i_owners: Array of owner addresses**.
- **s_required: Number of confirmations required for an action**.
- **s_governor: Address of the governor**.
- **s_totalSupply: Initial total supply of tokens**.

- **ETHERSCAN_API_LINK_URL: https://sepolia.etherscan.io/address/0x302fbb97ad6abbea18e207383c3549dbca18f85f**.
- **CONTRACT_ADRESS: 0x302FBB97aD6ABbea18e207383C3549dBcA18F85f**.

## Functions

## Confirm Transaction

```solidity
function confirmTransaction() public onlyOwners notConfirmed(msg.sender) {
    confirmations[msg.sender] = true;
    emit Confirmation(msg.sender);
}
```

## Revoke Confirmation

```solidity
function revokeConfirmation() public onlyOwners confirmed(msg.sender) {
    confirmations[msg.sender] = false;
    emit Revocation(msg.sender);
}
```

## Is Confirmed

```solidity
function isConfirmed() public view returns (bool) {
    uint256 count = 0;
    for (uint256 i = 0; i < i_owners.length; i++) {
        if (confirmations[i_owners[i]]) {
            count += 1;
        }
        if (count == s_required) {
            return true;
        }
    }
    return false;
}
```

## Add Owner

```solidity
function addOwner(address owner) public {
    if (isOwner[owner]) {
        revert OWNER_ALREADY_EXISTS();
    }
    i_owners.push(owner);
    isOwner[owner] = true;
    emit OwnerAddition(owner);
    changeRequirement(s_required + 1);
}
```

## Remove Owner

```solidity
function removeOwner(address owner) public {
    isOwner[owner] = false;
    for (uint256 i = 0; i < i_owners.length; i++) {
        if (i_owners[i] == owner) {
            i_owners[i] = i_owners[i_owners.length - 1];
            i_owners.pop();
            break;
        }
    }
    changeRequirement(s_required - 1);
}
```

## Change Requirement

```solidity
function changeRequirement(uint256 _required) public onlyOwners {
    if (_required > i_owners.length) {
        revert REQUIREMENTS_IS_HIGHER_THAN_NUMBER_OF_OWNERS();
    }
    s_required = _required;
    emit RequirementChange(_required);
}
```

## Mint Tokens

```solidity
function mint(address to, uint256 amount) public onlyGovernor {
    _mint(to, amount);
}
```

## Multi-Signature Mint

```solidity
function multiSigMint(address to, uint256 amount) public onlyOwners {
    if (!isConfirmed()) {
        revert NUMBER_OF_REQUIRED_OWNERS_NOT_REACHED();
    } else {
        _mint(to, amount);
    }
}
```

## Burn Tokens

```solidity
function burn(address from, uint256 amount) public onlyGovernor {
    _burn(from, amount);
}
```

## Multi-Signature Burn

```solidity
function multiSigBurn(address from, uint256 amount) public onlyOwners {
    if (!isConfirmed()) {
        revert NUMBER_OF_REQUIRED_OWNERS_NOT_REACHED();
    } else {
        _burn(from, amount);
    }
}
```

## Blacklist Address

```solidity
function blacklist(address member) public onlyGovernor {
    blacklisted[member] = true;
}
```

## Is Blacklisted

```solidity
function isBlacklisted(address member) public view returns (bool) {
    return blacklisted[member];
}
```

## Is Owner

```solidity
function isOwnersT(address owner) public view returns (bool) {
    return isOwner[owner];
}
```

## Remove From Blacklist

```solidity
function removeFromBlackList(address member) public onlyGovernor {
    if (!blacklisted[member]) {
        revert ADDRESS_NOT_IN_BLACKLIST();
    } else {
        blacklisted[member] = false;
    }
}
```

## Transfer

```solidity
function transfer(address to, uint256 amount) public override returns (bool) {
    if (isBlacklisted(msg.sender) || isBlacklisted(to)) {
        revert YOUR_ADDRESS_WAS_BLACKLISTED();
    }
    return super.transfer(to, amount);
}
```

## Change Governor

```solidity
function changeGovernor(address newGovernor) public {
    s_governor = newGovernor;
}
```

## Getter Functions

## Get Owners

```solidity
function getOwners() external view returns (address[] memory) {
    return i_owners;
}
```

## Get Required Number of Approvals

```solidity
function getRequiredNumberOfApproval() external view returns (uint256) {
    return s_required;
}
```

## Get Governor

```solidity
function getGovernor() external view returns (address) {
    return s_governor;
}
```

## Get Total Supply

```solidity
function getTotalSupply() external view returns (uint256) {
    return s_totalSupply;
}
```

## Conclusion

**The Gnaira smart contract implements a robust ERC20 token with added functionalities for minting, burning, and blacklisting, governed by a multi-signature approval system. This ensures enhanced security and governance, making it suitable for handling a country's financial transactions transparently and securely**.



## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
