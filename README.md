# Approval Target: Monkeypatching EIP-2612 support on ERC-20

## Motivation

ApprovalTarget is an immutable contract that accepts token approvals from users across various ERC-20s, then enables anyone with a valid user signature to transfer those tokens.
You can think of it like monkeypatching EIP-2612 support on all ERC-20 compliant tokens.

The more users that approve ApprovalTarget, and the dApps that implement `permitAndTransferFrom`, the less users will have to suffer the awful double-tx approve and spend UX.

### Draft EIP
Draft EIP can be found [here](./eip-draft.md).

## Getting Started

### Setup

`yarn`

### Compiling

`yarn compile`

### Testing

`yarn test `

### Reference

[EIP-2612](https://eips.ethereum.org/EIPS/eip-2612)

[Tally ETH Denver Bounty6 - Single Signed Approval Flow Using ApprovalTarget](https://docs.tally.cash/tally/ethdenver/bounties/bounty-6-ecosystem-wins-single-signed-approval-flow-using-approvaltarget-erc-20-transactions)
