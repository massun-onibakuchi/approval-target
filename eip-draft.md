---
eip: <to be assigned>
title: Approval flow using ApprovalTarget 
description: monkeypatching EIP-2612 support on all ERC-20 compliant tokens.
author: Tally (@tallycash), bakuchi (@massun-onibakuchi), paku (@paku-paku-pakuchi)
discussions-to: 
status: Draft
type: Standards 
category (*only required for Standards Track): ERC
created: 2021-03-20
requires (*optional):20
---

## Abstract

To use ERC-20 tokens in dApps, approving is needed, which is expensive.
Design a ApprovalTarget contract to create a single signed approval flow for ERC-20 tokens. This allows users to send approval transaction only once.

## Motivation

The motivation section should describe the "why" of this EIP. What problem does it solve? Why should someone want to implement this standard? What benefit does it provide to the Ethereum ecosystem? What use cases does this EIP address?

EIP-2612 allows abstraction in the ERC-20 `approve` method. But some of ERC-20 tokens do not have a `permit` function. Introducing ApprovalTarget indirectly allows approval by signature for all ERC-20 compliant tokens.

In addition ApprovalTarget replaces `approve` transaction with a signed approve and improves UX.

## Specification

The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).

ApprovalTarget has three functions.

```solidity
function nonces(address owner) external view returns (uint)

function PERMIT_AND_TRANSFER_FROM_TYPEHASH() external view returns (bytes32)

function permitAndTransferFrom(address erc20, address owner, address recipient, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external
```

The semantics of which are follows [EIP2612](https://eips.ethereum.org/EIPS/eip-2612)

NOTE: `spender` in the provided signature must be the same as `msg.sender`. `recipient` isn't been attested by a signature from `owner`, and is instead chosen by `msg.sender`, attested in the signature as `spender`.

If any of these conditions are not met, the `permitAndTransferFrom` call must revert.

```solidity
keccak256(abi.encodePacked(
   hex"1901",
   DOMAIN_SEPARATOR,
   keccak256(abi.encode(
             keccak256("PermitAndTransferFrom(address erc20,address owner,address spender,value,uint256 nonce,uint256 deadline)"),
            erc20,
            owner,
            msg.sender, // NOTE: spender
            amount,
            nonce,
            deadline))
))
```

where `DOMAIN_SEPARATOR` is defined according to EIP-712.

In summary the caller of the `permitAndTransferFrom` function must be `spender`. `spender` can choose `recipient`.

## Rationale

The `spender` is not provided in `permitAndTransferFrom` paramters. If `spender` is not `msg.sender`, the transaction will revert.

The `recipient` is provided by not the `owner` but the `spender`. So, the `recipient` isn't attested by a signature.

The `nonces` mapping is given for replay protection.

`spender` is essentially given a free option to submit or withhold the `PermitAndTransferFrom`. If this is a cause of concern, the `owner` can limit the time a `PermitAndTransferFrom` is valid for by setting `deadline` to a value in the near future.

## Backwards Compatibility

## Test Cases

Some basic tests can be found [here](https://github.com/massun-onibakuchi/approval-target/tree/main/test/ApprovalTarget.test.ts)

## Reference Implementation

[ApprovalTarget.sol](https://github.com/massun-onibakuchi/approval-target/ApprovalTarget.sol)

## Security Considerations

`transferFrom` implementations depend on each ERC-20 tokens. It is possible that the actual intended amount may not be sent such as fees on transfer or rebase tokens

The standard ERC-20 race condition for approvals applies to `permitAndTransferFrom` as well.

Signed Permit messages are censorable. `spender` have a option to withhold the signature. The `deadline` parameter is one mitigation to this.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).

## Citation

Tally, "Single Signed Approval Flow Using ApprovalTarget" https://docs.tally.cash/tally/ethdenver/bounties/bounty-6-ecosystem-wins-single-signed-approval-flow-using-approvaltarget-erc-20-transactions

[mhluongo](https://github.com/mhluongo), ApprovalTarget https://gist.github.com/mhluongo/be1e9aac69a6362657113fa8eaa5d0d8
