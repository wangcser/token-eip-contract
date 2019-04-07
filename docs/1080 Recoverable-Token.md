# EIP 1080: Recoverable Token 

| Author         | [Bradley Leatherwood](mailto:bradleat@inkibra.com)           |
| -------------- | ------------------------------------------------------------ |
| Discussions-To | <https://ethereum-magicians.org/t/erc-1080-recoverabletoken-standard/364> |
| Status         | Draft                                                        |
| Type           | Standards Track                                              |
| Category       | ERC                                                          |
| Created        | 2018-05-02                                                   |

## Summary

A standard interface for tokens that support **chargebacks, theft prevention, and lost & found** resolutions.

> 支持退款，防盗和找回（对于现实世界的缺陷我们可以在数字世界中将其完成）

## Abstract

The following standard allows for the implementation of a standard API for tokens extending ERC-20 or ERC-791. **This standard provides basic functionality to recover stolen or lost accounts, as well as provide for the chargeback of tokens.**

## Motivation

To mitigate the effects of **reasonably provable** token or asset loss or theft and to help resolve other conflicts. Ethereum’s protocol should not be modified because of loss, theft, or conflicts, but it is possible to solve these problems in the protocol layer.

> 关键在于这个合理的证明

## Specification

### RecoverableToken

### Methods

> 注意下面加粗的内容，合约只提供接口，但是调用接口的条件以及对合约的欺诈行为还需要更多的工作

#### claimLost

Reports the `lostAccount` address as being lost. MUST trigger the `AccountClaimedLost` event.

After the time configured in `getLostAccountRecoveryTimeInMinutes` **the implementer MUST provide a mechanism for determining the correct owner of the tokens held and moving the tokens to a new account.**

Account recoveries must trigger the `AccountRecovered` event.

```
function claimLost(address lostAccount) returns (bool success)
```

#### cancelLostClaim

Reports the `msg.sender`’s account as being not being lost. MUST trigger the `AccountClaimedLostCanceled` event.

MUST fail if an account recovery process has already begun.

Otherwise, this method MUST stop a dispute from being started to recover funds.

```
function claimLost() returns (bool success)
```

#### reportStolen

Reports the current address as being stolen. MUST trigger the `AccountFrozen` event. Successful calls MUST result in the `msg.sender`’s tokens being frozen.

**The implementer MUST provide a mechanism for determining the correct owner of the tokens held and moving the tokens to a new account.**

Account recoveries must trigger the `AccountRecovered` event.

```
function reportStolen() returns (bool success)
```

#### chargeback

Requests a reversal of transfer on behalf of `msg.sender`.

**The implementer MUST provide a mechanism for determining the correct owner of the tokens disputed and moving the tokens to the correct account.**

MUST comply with sender’s chargeback window as value configured by `setPendingTransferTimeInMinutes`.

```
function chargeback(uint256 pendingTransferNumber) returns (bool success)
```

#### getPendingTransferTimeInMinutes

Get the time an account has to chargeback a transfer.

```
function getPendingTransferTime(address account) view returns (uint256 minutes)
```

#### setPendingTransferTimeInMinutes

Sets the time `msg.sender`’s account has to chargeback a transfer.

MUST NOT change the time if the account has any pending transfers.

```
function setPendingTransferTime(uint256 minutes) returns (bool success)
```

#### getLostAccountRecoveryTimeInMinutes

Get the time account has to wait before a lost account dispute can start.

```
function getLostAccountRecoveryTimeInMinutes(address account) view returns (uint256 minutes)
```

#### setLostAccountRecoveryTimeInMinutes

Sets the time `msg.sender`’s account has to sit before a lost account dispute can start.

MUST NOT change the time if the account has open disputes.

```
function setLostAccountRecoveryTimeInMinutes(uint256 minutes) returns (bool success)
```

> 这个时间似乎是用来确认欺诈行为或者调解准备的，还需要看应用的情况

### Events

#### AccountRecovered

The recovery of an account that was lost or stolen.

```
event AccountClaimedLost(address indexed account, address indexed newAccount)
```

#### AccountClaimedLostCanceled

An account claimed as being lost.

```
event AccountClaimedLost(address indexed account)
```

#### AccountClaimedLost

An account claimed as being lost.

```
event AccountClaimedLost(address indexed account)
```

#### PendingTransfer

A record of a transfer pending.

```
event PendingTransfer(address indexed from, address indexed to, uint256 value, uint256 pendingTransferNumber)
```

#### ChargebackRequested

A record of a chargeback being requested.

```
event ChargebackRequested(address indexed from, address indexed to, uint256 value, uint256 pendingTransferNumber)
```

#### Chargeback

A record of a transfer being reversed.

```
event Chargeback(address indexed from, address indexed to, uint256 value, uint256 indexed pendingTransferNumber)
```

#### AccountFrozen

A record of an account being frozen. MUST trigger when an account is frozen.

```
event AccountFrozen(address indexed reported)
```

## Rationale

- A recoverable token standard can provide configurable saftey for users or contracts who desire this saftey.

- **Implementations of this standard will give users the ability to select a dispute resolution process on an opt-in basis and benefit the community by decreasing the necessity of consideration of token recovery actions.**

  > 这里才是重点：
  >
  > 1. 用户可以选择解决争议的流程
  > 2. 减少社区对恢复操作的压力

## Implementation

**Pending.**

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).