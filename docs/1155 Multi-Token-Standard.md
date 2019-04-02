# EIP 1155: ERC-1155 Multi Token Standard

> refer：<https://eips.ethereum.org/EIPS/eip-1155>

## Information

| Author         | [Witek Radomski](mailto:witek@enjin.com), [Andrew Cooke](mailto:andrew@enjin.com), [Philippe Castonguay](mailto:pc@horizongames.net), [James Therien](mailto:james@enjin.com), [Eric Binet](mailto:eric@enjin.com) |
| -------------- | ------------------------------------------------------------ |
| Discussions-To | <https://github.com/ethereum/EIPs/issues/1155>               |
| Status         | Last Call **(review ends 2019-03-28)**                       |
| Type           | Standards Track                                              |
| Category       | ERC                                                          |
| Created        | 2018-06-17                                                   |
| Requires       | [165](https://eips.ethereum.org/EIPS/eip-165)                |

## Summary

A standard interface for contracts that manage multiple token types. A single deployed contract may include any combination of fungible tokens, non-fungible tokens, or other configurations (for example, semi-fungible tokens).

> 一个同时支持三种代币类型的合约，来源于游戏业务的需求（用更小的开销发送更多种类的代币）

## Abstract

This standard outlines a smart contract interface that can represent any number of Fungible and Non-Fungible token types. Existing standards such as ERC-20 require deployment of separate contracts per token type. The ERC-721 standard’s Token ID is a single non-fungible index and the group of these non-fungibles is deployed as a single contract with settings for the entire collection. In contrast, the ERC-1155 Multi Token Standard allows for each Token ID to represent a new configurable token type, which may have its own metadata, supply and other attributes.

The `_id` parameter is contained in each function’s parameters and indicates a specific token or token type in a transaction.

## Motivation

Tokens standards like ERC-20 and ERC-721 require a separate contract to be deployed for each token type or collection. This places a lot of redundant bytecode on the Ethereum blockchain and limits certain functionality by the nature of separating each token contract into its own permissioned address. With the rise of blockchain games and platforms like Enjin Coin, game developers may be creating thousands of token types, and a new type of token standard is needed to support them. However, ERC-1155 is not specific to games, and many other applications can benefit from this flexibility.

> 需求：
>
> 1. 过去一个合约一种代币的模式在以太坊中制造了大量的冗余
> 2. 一个代币合约一个地址的做法限制了代币的某些功能
> 3. 以游戏为代表的应用需要在项目中使用大量的不同种类的代币

New functionality is possible with this design, such as transferring multiple token types at once, saving on transaction costs. Trading (escrow / atomic swaps) of multiple tokens can be built on top of this standard and it removes the need to “approve” individual token contracts separately. It is also easy to describe and mix multiple fungible or non-fungible token types in a single contract.

> 优势：
>
> 1. 支持同时发送多类型的代币，节约交易成本
> 2. 更易于构建复杂的交易场景
> 3. 更利于管理和使用

## Specification

### Interface

```
pragma solidity ^0.5.7;


interface ERC1155 /* is ERC165 */ {
   
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    event URI(string _value, uint256 indexed _id);

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;

    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}
```

### Token Receiver

```
pragma solidity ^0.5.7;

interface ERC1155TokenReceiver {

    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);

    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);
}
```

### Metadata

The URI value allows for ID substitution by clients. If the string `{id}` exists in any URI, clients MUST replace this with the actual token ID in hexadecimal form. This allows for large number of tokens to use the same on-chain string by defining a URI once, for a large collection of tokens.

> 使用 URI 来表示 token id 并赋予更加丰富的语义

```
pragma solidity ^0.5.7;

interface ERC1155Metadata_URI {

    function uri(uint256 _id) external view returns (string memory);
}
```

### Approval

The function `setApprovalForAll` allows an operator to manage one’s entire set of tokens on behalf of the approver. To permit approval of a subset of token IDs, an interface such as [ERC-1761 Scoped Approval Interface (DRAFT)](https://eips.ethereum.org/EIPS/eip-1761) is suggested.

> 操作员代表客户对其所有代币进行管理

## Rationale

### Metadata Choices

The `symbol` function (found in the ERC-20 and ERC-721 standards) was not included as we do not believe this is a globally useful piece of data to identify a generic virtual item / asset and are also prone to collisions. Short-hand symbols are used in tickers and currency trading, but they aren’t as useful outside of that space.

> 1155 合约中不再使用 symbol，理由如下：
>
> 1.  缩写很容易发生冲突
> 2. 适用范围有限（货币，电影票）

The `name` function (for human-readable asset names, on-chain) was removed from the standard to allow the Metadata JSON to be the definitive asset name and reduce duplication of data. This also allows localization for names, which would otherwise be prohibitively expensive if each language string was stored on-chain, not to mention bloating the standard interface. While this decision may add a small burden on implementers to host a JSON file containing metadata, we believe any serious implementation of ERC-1155 will already utilize JSON Metadata.

> 1155 合约不再使用 name ，理由如下：
>
> 1. 使用 URI + JSON 代替 name 来表达资产的语义
> 2. 可以支持 JSON 语义的本地化，不需要在链上存储大量的描述数据

### Upgrades

The requirement to emit `TransferSingle` or `TransferBatch` on balance change implies that a valid implementation of ERC-1155 redeploying to a new contract address MUST emit events from the new contract address to replicate the deprecated contract final state. It is valid to only emit a minimal number of events to reflect only the final balance and omit all the transactions that led to that state. The event emit requirement is to ensure that the current state of the contract can always be traced only through events. To alleviate the need to emit events when changing contract address, consider using the proxy pattern, such as described in ERC-1538. This will also have the added benefit of providing a stable contract address for users.

> 合约升级时需要保证新合约的 state 和 event 基于旧合约的最终状态
>
> 大量使用 event 是因为 event 是客户端跟踪系统状态变化的唯一方式

### Design decision: Supporting non-batch

The standard supports `safeTransferFrom` and `onERC1155Received` functions because they are significantly cheaper for single token-type transfers, which is arguably a common use case.

> 单独发送是批量发送的冗余，但是单独发送的方法传输的开销更小

### Design decision: Safe transfers only

The standard only supports safe-style transfers, making it possible for receiver contracts to depend on `onERC1155Received` or `onERC1155BatchReceived` function to be always called at the end of a transfer.

> 发送方法必须使用安全的实践
>
> 跨合约调用要考虑回调机制

### Guaranteed log trace

As the Ethereum ecosystem continues to grow, many dapps are relying on traditional databases and explorer API services to retrieve and categorize data. The ERC-1155 standard guarantees that event logs emitted by the smart contract will provide enough data to create an accurate record of all current token balances. A database or explorer may listen to events and be able to provide indexed and categorized searches of every ERC-1155 token in the contract.

> 完整的 event 机制能够保证基于合约可以回溯完整的交易记录和账户状态
>
> 加密货币的状态和记录存储于所有账户，合约代币存储于合约地址和他管理的空间上

### Approval

The function `setApprovalForAll` allows an operator to manage one’s entire set of tokens on behalf of the approver. It enables frictionless interaction with exchange and trade contracts.

> Approval 方法为交易所等场景提供了接口

Restricting approval to a certain set of Token IDs, quantities or other rules may be done with an additional interface or an external contract. The rationale is to keep the ERC-1155 standard as generic as possible for all use-cases without imposing a specific approval scheme on implementations that may not need it. Standard token approval interfaces can be used, such as the suggested [ERC-1761 Scoped Approval Interface (DRAFT)](https://eips.ethereum.org/EIPS/eip-1761) which is compatible with ERC-1155.

> 受限的 Approval 可以通过其他合约支持

## Usage

This standard can be used to represent multiple token types for an entire domain. Both Fungible and Non-Fungible tokens can be stored in the same smart-contract.

### Batch Transfers

＃＃＃＃　Batch Transfers

The `safeBatchTransferFrom` function allows for batch transfers of multiple token ids and values. The design of ERC-1155 makes batch transfers possible without the need for a wrapper contract, as with existing token standards. This reduces gas costs when more than one token type is included in a batch transfer, as compared to single transfers with multiple transactions.

Another advantage of standardized batch transfers is the ability for a smart contract to respond to the batch transfer in a single operation using `onERC1155BatchReceived`.

> 　使用一个合约接口就能完成多种代币的收发

### Batch Balance

The `balanceOfBatch` function allows clients to retrieve balances of multiple owners and token ids with a single call.

> 　支持一次查询多个用户的余额

### Enumerating from events

In order to keep storage requirements light for contracts implementing ERC-1155, enumeration (discovering the IDs and values of tokens) must be done using event logs. It is RECOMMENDED that clients such as exchanges and blockchain explorers maintain a local database containing the Token ID, Supply, and URI at the minimum. This can be built from each TransferSingle, TransferBatch, and URI event, starting from the block the smart contract was deployed until the latest block.

> 为了减小合约的存储开销，对合约内账户、代币、余额的查询（枚举）通过收集 event 实现，因此建议交易所和浏览器应用基于 event 维护本地的数据库（跟踪合约部署区块到最新区块即可）
>
> 因此，合约的 event 实现必须严格检查

ERC-1155 contracts must therefore carefully emit TransferSingle or TransferBatch events in any instance where tokens are created, minted, or destroyed.

### Non-Fungible Tokens

The following strategy is an example of how to mix fungible and non-fungible tokens together in the same contract. The top 128 bits of the uint256 `_id` parameter in any ERC-1155 function could represent the base token ID, while the bottom 128 bits might be used for any extra data passed to the contract.

Non-Fungible tokens can be interacted with using an index based accessor into the contract/token data set. Therefore to access a particular token set within a mixed data contract and particular NFT within that set, `_id` could be passed as `<uint128: base token id><uint128: index of NFT>`.

Inside the contract code the two pieces of data needed to access the individual NFT can be extracted with uint128(~0) and the same mask shifted by 128.

> 使用掩码 mask 机制将 NFT 的 index 和 Token id 结合到一起，前 128 位代表 token id，后 128 为代表 NFT index
>
> 在过去的合约中使用了两个状态来存储 NFT

### Example of split ID bits

```solidity
uint256 baseToken = 12345 << 128;
uint128 index = 50;

balanceOf(baseToken, msg.sender); // Get balance of the base token
balanceOf(baseToken + index, msg.sender); // Get balance of the Non-Fungible token index
```

### References

**Standards**

- [ERC-721 Non-Fungible Token Standard](https://eips.ethereum.org/EIPS/eip-721)
- [ERC-165 Standard Interface Detection](https://eips.ethereum.org/EIPS/eip-165)
- [ERC-1538 Transparent Contract Standard (DRAFT)](https://eips.ethereum.org/EIPS/eip-1538)
- [JSON Schema](https://json-schema.org/)
- [RFC 2119 Key words for use in RFCs to Indicate Requirement Levels](https://www.ietf.org/rfc/rfc2119.txt)

**Implementations**

- [ERC-1155 Reference Implementation](https://github.com/enjin/erc-1155)
- [Horizon Games - Multi-Token Standard](https://github.com/horizon-games/multi-token-standard)
- [Enjin Coin](https://enjincoin.io/) ([GitHub](https://github.com/enjin))
- [The Sandbox - Dual ERC-1155/721 Contract](https://github.com/pixowl/thesandbox-contracts/tree/master/src/Asset)

**Articles & Discussions**

- [Github - Original Discussion Thread](https://github.com/ethereum/EIPs/issues/1155)
- [ERC-1155 - The Crypto Item Standard](https://blog.enjincoin.io/erc-1155-the-crypto-item-standard-ac9cf1c5a226)
- [Here Be Dragons - Going Beyond ERC-20 and ERC-721 To Reduce Gas Cost by ~80%](https://medium.com/horizongames/going-beyond-erc20-and-erc721-9acebd4ff6ef)
- [Blockonomi - Ethereum ERC-1155 Token Perfect for Online Games, Possibly More](https://blockonomi.com/erc1155-gaming-token/)
- [Beyond Gaming - Exploring the Utility of ERC-1155 Token Standard!](https://blockgeeks.com/erc-1155-token/)

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).