# EIP 902: Token Validation 

| Author         | [Brooklyn Zelenka](https://github.com/expede), [Tom Carchrae](https://github.com/carchrae), [Gleb Naumenko](https://github.com/naumenkogs) |
| -------------- | ------------------------------------------------------------ |
| Discussions-To | <https://ethereum-magicians.org/t/update-on-erc902-validated-token/1639> |
| Status         | Draft                                                        |
| Type           | Standards Track                                              |
| Category       | ERC                                                          |
| Created        | 2018-02-14                                                   |
| Requires       | [1066](https://eips.ethereum.org/EIPS/eip-1066)              |

# Simple Summary

A protocol for services **providing token ownership and transfer validation**.

> 一个代币注册合约，提供代币验证能力

# Abstract

This standard provides **a registry contract method for authorizing token transfers**. By nature, this covers both initially issuing tokens to users (ie: transfer from contract to owner), transferring tokens between users, and token spends.

> 代币注册合约，实现对代币的认证

# Motivation

The tokenization of assets has wide application, not least of which is financial instruments such as securities and security tokens. Most jurisdictions have placed legal constraints on what may be traded, and who can hold such tokens which are regarded as securities. **Broadly this includes KYC and AML validation, but may also include time-based spend limits, total volume of transactions, and so on**.

> 资产代币化在现实中越来越多地被当做证券来处理，因此需要对其进行 KYC 和 AML 验证，以及一些交易限制

**Regulators and sanctioned third-party compliance agencies need some way to link off-chain compliance information such as identity and residency to an on-chain service.** The application of this design is broader than legal regulation, encompassing all manner of business logic permissions for the creation, management, and trading of tokens.

> 线下合规的机构需要一种将合规信息与链上服务链接的机制
>
> 

Rather than each token maintaining its own whitelist (or other mechanism), it is preferable to share on-chain resources, rules, lists, and so on. There is also a desire to aggregate data and rules spread across multiple validators, or to apply complex behaviours (ex. switching logic, gates, state machines) to apply distributed data to an application.

> 上面介绍了统一认证的好处：分享信息，聚合链上资源

# Specification

### TokenValidator

```solidity
interface TokenValidator {
    function check(
        address _token,
        address _subject
    ) public returns(byte statusCode)

    function check(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) public returns (byte statusCode)
}
```

### Methods

#### `check`/2

```
function check(address _token, address _subject) public returns (byte _resultCode)
```

> parameters
>
> - `_token`: the token under review
> - `_subject`: the user or contract to check
>
> *returns* an ERC1066 status code

#### `check`/4

```
function check(address token, address from, address to, uint256 amount) public returns (byte resultCode)
```

> parameters
>
> - `_token`: the token under review
> - `_from`: in the case of a transfer, who is relinquishing token ownership
> - `_to`: in the case of a transfer, who is accepting token ownership
> - `_amount`: The number of tokens being transferred
>
> *returns* an ERC1066 status code

### ValidatedToken

```solidity
interface ValidatedToken {
    event Validation(
        address indexed subject,
        byte   indexed result
    )

    event Validation(
        address indexed from,
        address indexed to,
        uint256 value,
        byte   indexed statusCode
    )
}
```

### Events

#### `Validation`/2

```
event Validation(address indexed subject, byte indexed resultCode)
```

This event MUST be fired on return from a call to a `TokenValidator.check/2`.

> parameters
>
> - `subject`: the user or contract that was checked
> - `statusCode`: an ERC1066 status code

#### `Validation`/4

```solidity
event Validation(
    address indexed from,
    address indexed to,
    uint256 amount,
    byte   indexed statusCode
)
```

This event MUST be fired on return from a call to a `TokenValidator.check/4`.

> parameters
>
> - `from`: in the case of a transfer, who is relinquishing token ownership
> - `to`: in the case of a transfer, who is accepting token ownership
> - `amount`: The number of tokens being transferred
> - `statusCode`: an ERC1066 status code

# Rationale

This proposal includes a financial permissions system on top of any financial token. This design is not a general **roles/permission system**. In any system, the more you know about the context where a function will be called, the more powerful your function can be. By restricting ourselves to token transfers (ex. ERC20 or EIP-777), we can make assumptions about the use cases our validators will need to handle, and can make the API both small, useful, and extensible.

The events are fired by the calling token. Since `Validator`s may aggregate or delegate to other `Validator`s, it would generate a lot of useless events were it the `Validator`’s responsibility. This is also the reason why we include the `token` in the `call/4` arguments: a `Validator` cannot rely on `msg.sender` to determine the token that the call is concerning.

We have also seen a similar design from [R-Token](https://github.com/harborhq/r-token) that uses an additional field: `spender`. While there are potential use cases for this, it’s not widely used enough to justify passing a dummy value along with every call. Instead, such a call would look more like this:

```solidity
function approve(address spender, uint amount) public returns (bool success) {
    if (validator.check(this, msg.sender, spender, amount) == okStatusCode) {
        allowed[msg.sender][spender] = amount;
        Approval(msg.sender, spender, amount);
        return true;
    } else {
        return false;
    }
}
```

A second `check/2` function is also required, that is more general-purpose, and does not specify a transfer amount or recipient. This is intended for general checks, such as checking roles (admin, owner, &c), or if a user is on a simple whitelist.

We have left the decision to make associated `Validator` addresses public, private, or hardcoded up to the implementer. The proposed design does not include a centralized registry. It also does not include an interface for a `Validated` contract. A token may require one or many `Validator`s for different purposes, requiring different validations for different, or just a single `Validator`. The potential use cases are too varied to provide a single unified set of methods. We have provided a set of example contracts [here](https://github.com/Finhaven/ValidatedToken/) that may be inherited from for common use cases.

The status codes in the `byte` returns are unspecified. Any status code scheme may be used, though a general status code proposal is fortcoming.

**By only defining the validation check, this standard is widely compatible with ERC-20, EIP-721, EIP-777, future token standards, centralized and decentralized exchanges, and so on.**

# Implementation

[Reference implementation](https://github.com/expede/validated-token/)

# Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).