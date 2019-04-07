# EIP 1261: Membership Verification Token (MVT)

> Refer:  <https://eips.ethereum.org/EIPS/eip-1261>

## Information

| Author         | [Chaitanya Potti](https://github.com/chaitanyapotti), [Partha Bhattacharya](https://github.com/pb25193) |
| -------------- | ------------------------------------------------------------ |
| Discussions-To | <https://github.com/ethereum/EIPs/issues/1261>               |
| Status         | Draft                                                        |
| Type           | Standards Track                                              |
| Category       | ERC                                                          |
| Created        | 2018-07-14                                                   |
| Requires       | [165](https://eips.ethereum.org/EIPS/eip-165), [173](https://eips.ethereum.org/EIPS/eip-173) |

## Summary

A standard interface for Membership Verification Token(MVT).

> 会员认证代币的标准接口
>
> 注意，EIP 是对合约接口的描述

##　Abstract

The following standard allows for the implementation of a standard API for Membership Verification Token within smart contracts(called entities). **This standard provides basic functionality to track membership of individuals in certain on-chain ‘organizations’.** This allows for several use cases like automated compliance, and several forms of governance and membership structures.

> 该标准提供了绑定和认证成员与组织关系的基本接口

We considered **use cases of MVTs** being assigned to individuals which **are non-transferable and revocable by the owner.** **MVTs can represent proof of recognition, proof of membership, proof of right-to-vote and several such otherwise abstract concepts on the blockchain.** The following are some examples of those use cases, and it is possible to come up with several others:

> 　MVT 不能转让和恢复（会员资格的特点），可用于证明能力，证明会籍，证明投票权 …

- **Voting**: **Voting is inherently supposed to be a permissioned activity**. So far, onchain voting systems are only able to carry out voting with coin balance based polls. This can now change and take various shapes and forms.

  > 目前的链上投票更像民意调查

- **Passport issuance**, **social benefit distribution**, **Travel permit issuance**, **Drivers licence** issuance are all applications which can **be abstracted into membership**, **that is belonging of an individual to a small set, recognized by some authority as having certain entitlements, without needing any individual specific information**(right to welfare, freedom of movement, authorization to operate vehicles, immigration)

  > 护照签发，社会福利分配，旅行证签发，驾照签发
  >
  > 对会籍的定义：由某个特权机构认可的一个小团体，团体内的成员具有一定的权益而不需要任何的个人信息

- **Investor permissioning**: Making regulatory compliance a simple on chain process. **Tokenization of securities, that are streamlined to flow only to accredited addresses**, tracing and certifying on chain addresses for AML purposes.

  > 投资许可：MVT 引入成员认证，使得代币化的内容不能流向未被认证的地址

- **Software licencing**: Software companies like game developers can use the protocol to authorize certain hardware units(consoles) to download and use specific software(games)

  > 软件授权，可能是个好主意，因为软件和游戏都是良好数字化了的

In general, an individual can have different memberships in his day to day life. The protocol allows for the creation of software that puts everything all at one place. **His identity can be verified instantly**. **Imagine a world where you don’t need to carry a wallet full of identity cards** (Passport, gym membership, SSN, Company ID etc) and **organizations can easily keep track of all its members. Organizations can easily identify and disallow fake identities.**

> 虽然说目前的公链上确认交易很慢，但是查询交易是很快的，因此对于这类需要大量认证的场景可能比较合适
>
> 做这件事需要考虑实际的运维问题，是否能够迁移，方便迁移？
>
> 如果说支付宝是改革了现代人的钱包，那么 MVT 就是改革了现代人的卡包

Attributes are a huge part of **ERC-1261 which help to store identifiable information regarding its members.** Polls can make use of attributes to calculate the voterbase. E.g: Users should belong to USA entity and not belong to Washington state attribute to be a part of a poll.

> 认证信息在 1261 提案中描述

There will exist a mapping table that maps attribute headers to an array of all possible attributes. This is done in order to subdivide entities into subgroups which are exclusive and exhaustive. For example, header: blood group alphabet Array: [ o, a, b, ab ] header: blood group sign Array: [ +, - ]

NOT an example of exclusive exhaustive: Header: video subscription Array: [ Netflix, HBO, Amazon ] Because a person is not necessitated to have EXACTLY one of the elements. He or she may have none or more than one.

## Motivation

A standard interface allows any user,applications to work with any MVT on Ethereum. We provide for simple ERC-1261 smart contracts. Additional applications are discussed below.

This standard is inspired from the fact that voting on the blockchain is done with token balance weights. This has been greatly detrimental to the formation of flexible governance systems on the blockchain, despite the tremendous governance potential that blockchains offer. The idea was to **create a permissioning system** that allows organizations to vet people once into the organization on the blockchain, and then gain immense flexibility in the kind of governance that can be carried out.

> 目前基于加密货币的投票方式有害链上组织和链上治理的发展
>
> 利用 MVT 可以在自由的区块链世界中创造一个具有权限的系统

We have also reviewed **other Membership EIPs including EIP-725/735 Claim Registry**. **A significant difference between #735 claims and #1261 MVTs is information ownership**. In #735 the Claim Holder owns any claims made about themselves. The problem with this is that there is no way for a Claim Issuer to revoke or alter a claim once it has been issued. While #735 does specify a removeClaim method, a malicious implementation could simply ignore that method call, because they own the claim.

> 撤回问题在这个场景中是很关键的

Imagine that **SafeEmploy™, a background checking company**, issues a claim about Timmy. The claim states that Timmy has never been convicted of any felonies. Timmy makes some bad decisions, and now that claim is no longer true. SafeEmploy™ executes removeClaim, but Timmy’s #735 contract just ignores it, because Timmy wants to stay employed (and is crypto-clever). #1261 MVTs do not have this problem. Ownership of a badge/claim is entirely determined by the contract issuing the badges, not the one receiving them. The issuer is free to remove or change those badges as they see fit.

> 举一个奖状的例子：小明做了好事被授予了好人奖状，这个奖状的解释权到了小明手里，小明可能做了坏事但依然能够使用这个奖状，对于 MVT 来说，区别就在于奖状的解释权在合约发行者手里，它具有发出代币的解释权

> 下文介绍设计团队在代币的适用性和可性度上的考量
>
> 对权力的量化导致了代币功能和接口设计上的不同

**Trade-off between trustlessness and usability**: To truly understand the value of the protocol, it is important to understand the trade-off we are treading on. 

**The MVT contract allows the creator to revoke the token, and essentially confiscate the membership of the member in question**. To some, this might seem like an unacceptable flaw, however **this is a design choice**, and not a flaw. 

> MVT 的设计允许合约所有者撤回甚至没收已发行的代币，下面是设计理由

The choice may seem to place a great amount of trust in the individuals who are managing the entity contract(entity owners). If the interests of the entity owner conflict with the interests of the members, the owner may resort to addition of fake addresses(to dominate consensus) or evicting members(to censor unfavourable decisions). At first glance this appears to be a major shortcomings, because **the blockchain space is used to absolute removal of authority in most cases. Even the official definition of a dapp requires the absence of any party that manages the services provided by the application.** 

> 这样的设计导致成员需要对管理者的极大的信任，当二者之间发生利益冲突时，管理者可能会作弊
>
> 这样的设计与公链的目标相违背

However, the trust in entity owners is not misplaced, if it can be ensured that the interests of entity owners are aligned with the interests of members. 

> 作者认为只要保证管理者和成员的利益一致，那么对管理者的信任就不会错位

Another criticism of such a system would be that the standard edge of blockchain intermediation - “you cannot bribe the system if you don’t know who to bribe” - no longer holds. It is possible to bribe an entity owner into submission, and get them to censor or fake votes. 

> 另一个存在的问题：可以贿赂系统

There are several ways to respond to this argument. 

- **First** of all, all activities, such as addition of members, and removal of members can be tracked on the blockchain and traces of such activity cannot be removed. **It is not difficult to build analytics tools to detect malicious activity**(adding 100 fake members suddenly who vote in the direction/sudden removal of a number of members voting in a certain direction). 

  > 贿赂行为和欺诈行为在区块链系统中是可审计的，可以通通过数据分析来发现

- **Secondly, the entity owners’ power is limited to the addition and removal of members.** This means that they cannot tamper any votes. They can only alter the counting system to include fake voters or remove real voters. Any sensible auditor can identify the malicious/victim addresses and create an open source audit tool to find out the correct results. **The biggest loser in this attack will be the entity owner, who has a reputation to lose.** Finally, **one must understand why we are taking a step away from trustlessness in this trade-off. The answer is usability.** 

  > 其次，管理员的权限是有限的，也是可以审计的
  >
  > 欺诈行为的最终受害者是团队的拥有者
  >
  > 因此，我们牺牲系统无需信任的特性来实现更好的可用性

**Introducing a permissioning system expands the scope of products and services that can be delivered through the blockchain, while leveraging other aspects of the blockchain**(cheap, immutable, no red-tape, secure). 

> 在区块链中引入特权系统扩展了区块链的产品和服务范围，同时利用了区块链其他方面的优势

Consider the example of the driver licence issuing agency using the ERC-1300 standard. This is a service that simply cannot be deployed in a completely trustless environment. The introduction of permissioned systems expanded the scope of services on the blockchain to cover this particular service. Sure, they have the power to revoke a person’s licence for no reason. But will they? Who stands to lose the most, if the agency acts erratically? The agency itself. Now consider the alternative, the way licences(not necessarily only drivers licence, but say shareholder certificates and so on) are issued, the amount of time consumed, the complete lack of transparency. One could argue that if the legacy systems providing these services really wanted to carry out corruption and nepotism in the execution of these services, the present systems make it much easier to do so. Also, they are not transparent, meaning that there is no way to even detect if they act maliciously. All that being said, we are very excited to share our proposal with the community and open up to suggestions in this space.

> 在公链中引入联盟链扩展了公链的服务范围，而在联盟中作弊的行为最终会影响联盟的信誉，因此这种行为会得到克制。

## Specification

### Interface



### Metadata



## Rationale

There are many potential uses of Ethereum **smart contracts that depend on tracking membership**. Examples of existing or planned MVT systems are Vault, a DAICO platform, and Stream, a security token framework. Future uses include the implementation of direct democracy, in-game memberships and badges, licence and travel document issuance, electronic voting machine trails, software licencing and many more.

**MVT Word Choice:**

Since **the tokens are non transferable and revocable**, **they function like membership cards**. Hence the word membership verification token.

**Transfer Mechanism**

**MVTs can’t be transferred. This is a design choice**, and one of the features that distinguishes this protocol. **Any member can always ask the issuer to revoke the token from an existing address and assign to a new address.** One can think of the set of MVTs as identifying a user, and you cannot split the user into parts and have it be the same user, but you can transfer a user to a new private key.

> 可以通过撤销和重新发布来完成类似与挂失的操作

**Assign and Revoke mechanism**

> 可以实现更多的机制

The assign and revoke functions’ documentation only specify conditions when the transaction MUST throw. Your implementation MAY also throw in other situations. This allows implementations to achieve interesting results:

- **Disallow additional memberships after a condition is met** — Sample contract available on Github
- **Blacklist certain address from receiving MV tokens** — Sample contract available on Github
- **Disallow additional memberships after a certain time is reached** — Sample contract available on Github
- **Charge a fee to user of a transaction** — require payment when calling `assign` and `revoke` so that condition checks from external sources can be made

**ERC-173 Interface**

> 使用 173 进行所有权管理

We chose Standard Interface for Ownership (ERC-173) to manage the ownership of a ERC-1261 contract.

A future EIP/ Zeppelin may create a multi-ownable implementation for ownership. We strongly support such an EIP and it would allow your ERC-1261 implementation to implement `ERC1261Metadata`, or other interfaces by delegating to a separate contract.

**ERC-165 Interface**

> 使用 165 定义合约的外部接口

We chose Standard Interface Detection (ERC-165) to expose the interfaces that a ERC-1261 smart contract supports.

**A future EIP may create a global registry of interfaces for contracts**. We strongly support such an EIP and it would allow your ERC-1261 implementation to implement `ERC1261Metadata`, or other interfaces by delegating to a separate contract.

**Gas and Complexity** (regarding the enumeration extension)

This specification contemplates implementations that manage a few and *arbitrarily large* numbers of MVTs. If your application is able to grow then avoid using for/while loops in your code. These indicate your contract may be unable to scale and gas costs will rise over time without bound

**Privacy**

Personal information: The protocol does not put any personal information on to the blockchain, so there is no compromise of privacy in that respect. Membership privacy: The protocol by design, makes it public which addresses are/aren’t members. Without making that information public, it would not be possible to independently audit governance activity or track admin(entity owner) activity.

**Metadata Choices** (metadata extension)

We have required `name` and `symbol` functions in the metadata extension. Every token EIP and draft we reviewed (ERC-20, ERC-223, ERC-677, ERC-777, ERC-827) included these functions.

We remind implementation authors that the empty string is a valid response to `name` and `symbol` if you protest to the usage of this mechanism. **We also remind everyone that any smart contract can use the same name and symbol as *your* contract.** How a client may determine which ERC-1261 smart contracts are well-known (canonical) is outside the scope of this standard.

**A mechanism is provided to associate MVTs with URIs.** We expect that many implementations will take advantage of this to provide metadata for each MVT system. The URI MAY be mutable (i.e. it changes from time to time). We considered an MVT representing membership of a place, in this case metadata about the organization can naturally change.

Metadata is returned as a string value. Currently this is only usable as calling from `web3`, not from other contracts. This is acceptable because we have not considered a use case where an on-blockchain application would query such information.

*Alternatives considered: put all metadata for each asset on the blockchain (too expensive), use URL templates to query metadata parts (URL templates do not work with all URL schemes, especially P2P URLs), multiaddr network address (not mature enough)*

> 直接在区块链上存放原始数据是十分昂贵的，可以使用 URI 来替代 

**Community Consensus**

We have been very inclusive in this process and invite anyone with questions or contributions into our discussion. However, this standard is written only to support the identified use cases which are listed herein.

## Backwards Compatibility

We have adopted `name` and `symbol` semantics from the ERC-20 specification.

Example MVT implementations as of July 2018:

- Membership Verification Token(https://github.com/chaitanyapotti/MembershipVerificationToken)

## Test Cases

Membership Verification Token ERC-1261 Token includes test cases written using Truffle.

## Implementations

Membership Verification Token ERC1261 – a reference implementation

- MIT licensed, so you can freely use it for your projects
- Includes test cases
- Also available as a npm package - npm i membershipverificationtoken

## References

**Standards**

1. ERC-20 Token Standard. https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
2. ERC-165 Standard Interface Detection. https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
3. ERC-725/735 Claim Registry https://github.com/ethereum/EIPs/blob/master/EIPS/eip-725.md
4. ERC-173 Owned Standard. https://github.com/ethereum/EIPs/issues/173
5. JSON Schema. https://json-schema.org/
6. Multiaddr. https://github.com/multiformats/multiaddr
7. RFC 2119 Key words for use in RFCs to Indicate Requirement Levels. https://www.ietf.org/rfc/rfc2119.txt

**Issues**

1. The Original ERC-1261 Issue. https://github.com/ethereum/eips/issues/1261
2. Solidity Issue #2330 – Interface Functions are Axternal. https://github.com/ethereum/solidity/issues/2330
3. Solidity Issue #3412 – Implement Interface: Allow Stricter Mutability. https://github.com/ethereum/solidity/issues/3412
4. Solidity Issue #3419 – Interfaces Can’t Inherit. https://github.com/ethereum/solidity/issues/3419

**Discussions**

1. Gitter #EIPs (announcement of first live discussion). https://gitter.im/ethereum/EIPs?at=5b5a1733d2f0934551d37642
2. ERC-1261 (announcement of first live discussion). https://github.com/ethereum/eips/issues/1261

**MVT Implementations and Other Projects**

1. Membership Verification Token ERC-1261 Token. https://github.com/chaitanyapotti/MembershipVerificationToken

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).