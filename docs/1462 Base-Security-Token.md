# EIP 1462: Base Security Token

> refer: <https://eips.ethereum.org/EIPS/eip-1462>

## Information

| Author         | [Maxim Kupriianov](mailto:mk@atlant.io), [Julian Svirsky](mailto:js@atlant.io) |
| -------------- | ------------------------------------------------------------ |
| Discussions-To | <https://ethereum-magicians.org/t/erc-1462-base-security-token/1501> |
| Status         | Draft                                                        |
| Type           | Standards Track                                              |
| Category       | ERC                                                          |
| Created        | 2018-10-01                                                   |
| Requires       | [20](https://eips.ethereum.org/EIPS/eip-20), [1066](https://eips.ethereum.org/EIPS/eip-1066) |

## Summary

**An extension to ERC-20** standard token that **provides compliance with securities regulations and legal enforceability**.

> 1462 提案是对 20 代币的合规性补充，提供了证券法规和法律执行的基础。

## Abstract

This EIP defines **a minimal set of additions** to the default token standard such as [ERC-20](https://eips.ethereum.org/EIPS/eip-20), that **allows for compliance with domestic and international legal requirements**. Such requirements include **KYC (Know Your Customer) and AML (Anti Money Laundering) regulations**, and the ability to lock tokens for an account, and restrict them from transfer due to a legal dispute. Also the ability to attach additional legal documentation, in order to set up a dual-binding relationship between the token and off-chain legal entities.

> 补充了一下的功能：
>
> 1. 锁定非法账户，限制其交易
> 2. 为合约绑定相关法律法规

The scope of this standard is being kept as narrow as possible to avoid restricting potential use-cases of this base security token. Any additional functionality and limitations not defined in this standard may be enforced on per-project basis.

> 代币的设计上依从最小原则，为了避免过多的设计影响其潜在的使用场景

## Motivation

**There are several security token standards** that have been proposed recently. Examples include [ERC-1400/ERC-1411](https://github.com/ethereum/EIPs/issues/1411), also [ERC-1450](https://github.com/ethereum/EIPs/issues/1450). We have concerns about each of them, mostly because the scope of each of these EIPs contains many project-specific or market-specific details. Since many EIPs are coming from the respective backing companies, they capture many niche requirements that are excessive for a general case.

> 来自于项目方背景的相关提案考虑了过多的场景细节，缺乏一般性

For instance, ERC-1411 uses dependency on [ERC-1410](https://github.com/ethereum/eips/issues/1410) but it falls out of the “security tokens” scope. Also its dependency on [ERC-777](https://github.com/ethereum/eips/issues/777]) will block the adoption for a quite period of time before ERC-777 is finalized, but the integration guidelines for existing ERC-20 workflows are not described in that EIP, yet. Another attempt to make a much simpler base standard [ERC-1404](https://github.com/ethereum/EIPs/issues/1404) is missing a few important points, specifically it doesn’t provide enough granularity to distinguish between different ERC-20 transfer functions such as `transfer` and `transferFrom`. It also doesn’t provide a way to bind legal documentation to the issued tokens.

> 和已有项目的对比

What we propose in this EIP is **a simple and very modular solution** for creating a base security token **for the widest possible scope of applications**, so it can be used by other issuers to build upon. The issuers should be able to add more restrictions and policies to the token, using the functions and implementation proposed below, but they must not be limited in any way while using this ERC.

> 我们的方案具有最宽广适用范围条件下的最简单的方案，可以作为其他项目的基础设施

## Specification

### Interface

```go
interface BaseSecurityToken /* is ERC-20 */ {
    // Checking functions
    function checkTransferAllowed (address from, address to, uint256 value) public view returns (byte);
    function checkTransferFromAllowed (address from, address to, uint256 value) public view returns (byte);
    function checkMintAllowed (address to, uint256 value) public view returns (byte);
    function checkBurnAllowed (address from, uint256 value) public view returns (byte);

    // Documentation functions
    function attachDocument(bytes32 _name, string _uri, bytes32 _contentHash) external;
    function lookupDocument(bytes32 _name) external view returns (string, bytes32);
}
```

### Transfer Checking Functions

We introduce four new functions that should be used to check that the actions are allowed for the provided inputs. The implementation details of each function are left for the token issuer, it is the issuer’s responsibility to add all necessary checks that will validate an operation in accordance with KYC/AML policies and legal requirements set for a specific token asset.

> 增加了4 个合法性验证接口

Each function must return a status code from the common set of Ethereum status codes (ESC), according to [ERC-1066](https://eips.ethereum.org/EIPS/eip-1066). Localization of these codes is out of the scope of this proposal and may be optionally solved by adopting [ERC-1444](https://github.com/ethereum/EIPs/pull/1444) on the application level. If the operation is allowed by a checking function, the return status code must be `0x11` (Allowed) or an issuer-specific code with equivalent but more precise meaning. If the operation is not allowed by a checking function, the status must be `0x10` (Disallowed) or an issuer-specific code with equivalent but more precise meaning. Upon an internal error, the function must return the most relevant code from the general code table or an issuer-specific equivalent, example: `0xF0` (Off-Chain Failure).

> 接口返回以太坊状态码

**For ERC-20 based tokens,**

- It is required that `transfer` function must be overridden with logic that checks the corresponding checkTransferAllowed return status code.

- It is required that `transferFrom` function must be overridden with logic that checks the corresponding `checkTransferFromAllowed` return status code.

- It is required that `approve` function must be overridden with logic that checks the corresponding `checkTransferFromAllowed` return status code.

- Other functions such as `mint` and `burn` must be overridden, if they exist in the token implementation, they should check `checkMintAllowed` and `checkBurnAllowed` status codes accordingly.

  > 需要对转账接口增加合法性检验的约束

**For ERC-777 based tokens,**

- It is required that `send` function must be overridden with logic that checks the corresponding return status codes:
  - `checkTransferAllowed` return status code, if transfer happens on behalf of the tokens owner;
  - `checkTransferFromAllowed` return status code, if transfer happens on behalf of an operator (i.e. delegated transfer).
- It is required that `burn` function must be overridden with logic that checks the corresponding `checkBurnAllowed` return status code.
- Other functions, such as `mint` must be overridden, if they exist in the token implementation, e.g. if the security token is mintable. `mint` function must call `checkMintAllowed` ad check it return status code.

For both cases,

- It is required for guaranteed compatibility with ERC-20 and ERC-777 wallets that each checking function returns `0x11` (Allowed) if not overridden with the issuer’s custom logic.
- It is required that all overriden checking functions must revert if the action is not allowed or an error occured, according to the returned status code.

Inside checker functions the logic is allowed to use any feature available on-chain: perform calls to registry contracts with whitelists/blacklists, use built-in checking logic that is defined on the same contract, or even run off-chain queries through an oracle.

> 这里列出了合法性检查接口内容的实施建议

### Documentation Functions

We also introduce two new functions that should be used for document management purposes. Function `attachDocument` adds **a reference pointing to an off-chain document**, **with specified name, URI and contents hash**. The hashing algorithm is not specified within this standard, but the resulting hash must not be longer than 32 bytes. Function `lookupDocument` gets the referenced document by its name.

- It is not required to use documentation functions, they are optional and provided as a part of a legal framework.
- It is required that if `attachDocument` function has been used, the document reference must have a unique name, overwriting the references under same name is not allowed. All implementations must check if the reference under the given name is already existing.

> 合约可以通过 hash 的方式引用其适用的法律文件

## Rationale

**This EIP targets both ERC-20 and ERC-777 based tokens**, although the most emphasis is given to ERC-20 due to its widespread adoption. However, this extension is designed to be compatible with the forthcoming ERC-777 standard, as well.

All checking functions are named with prefixes `check` since they **return check status code, not booleans**, because that **is important to facilitate the debugging and tracing process**. It is responsibility of the issuer to implement the logic that will handle the return codes appropriately. Some handlers will simply throw errors, other handlers would log information for future process mining. More rationale for status codes can be seen in [ERC-1066](https://eips.ethereum.org/EIPS/eip-1066).

We require two different transfer validation functions: `checkTransferAllowed` and `checkTransferFromAllowed` since the corresponding `transfer` and `transferFrom` are usually called in different contexts. 

> transfer 和 transferFrom 常用于不同的上下文环境中，虽然 transferFrom 足够包含 transfer 的所有功能，但是在某些场景下二者还是应该被区别对待

Some token standards such as [ERC-1450](https://github.com/ethereum/EIPs/issues/1450) explicitly disallow use of `transfer`, while allowing only `transferFrom`. There might be also different complex scenarios, where `transfer` and `transferFrom` should be treated differently. ERC-777 is relying on its own `send` for transferring tokens, so it is reasonable to switch between checker functions based on its call context. We decided to omit the `checkApprove` function since it would be used in exactly the same context as `checkTransferFromAllowed`. In many cases it is required not only regulate securities transfers, but also restrict burn and `mint` operations, and additional checker functions have been added for that.

The documentation functions that we propose here are a must-have tool to create **dual-bindings** with off-chain legal documents, **a great example** of this can be seen in [Neufund’s Employee Incentive Options Plan](https://medium.com/@ZoeAdamovicz/37376fd0384a) legal framework that implements full legal enforceability: **the smart contract refers to printed ESOP Terms & Conditions Document, which itself refers back to smart contract.** This is becoming a widely adopted practice even in cases where there are no legal requirements to reference the documents within the security token. However they’re almost always required, and it’s a good way to attach useful documentation of various types.

> 双绑定：合约指向文件且文件指向合约

## Backwards Compatibility

This EIP is fully backwards compatible as its implementation extends the functionality of ERC-20 and ERC-777 tokens.

## Implementation

- https://github.com/AtlantPlatform/BaseSecurityToken