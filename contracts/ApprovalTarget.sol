// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IApprovalTarget {
    function permitAndTransferFrom(
        address erc20,
        address owner,
        address recipient,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

/// @notice ApprovalTarget is an immutable contract that accepts token approvals
///         from users across various ERC-20s, then enables anyone with a valid
///         user signature to transfer those tokens. You can think of it like
///         monkeypatching EIP-2612 support on all ERC-20 compliant tokens.
///
///         The more users that approve ApprovalTarget, and the dApps that
///         implement `permitAndTransferFrom`, the less users will have to
///         suffer the awful double-tx approve and spend UX.
contract ApprovalTarget is EIP712, ReentrancyGuard, IApprovalTarget {
    using SafeERC20 for IERC20;

    mapping(address => uint256) public nonces;

    /// @notice Returns EIP-712 PermitAndTransferFrom message typehash. Used to
    ///         construct the EIP2612-inspired signature provided to
    ///         `permitAndTransferFrom` function.
    bytes32 public constant PERMIT_AND_TRANSFER_FROM_TYPEHASH =
        keccak256(
            "PermitAndTransferFrom(address erc20,address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    // solhint-disable-next-line no-empty-blocks
    constructor() EIP712("ApprovalTarget", "1") {}

    /// @notice Given a pre-existing approval from `owner` to this contract,
    ///         and a valid secp265k1 signature authorizing the move by
    ///         `msg.sender`, transfer `amount` tokens in the `erc20` token
    ///         contract from `owner` to `recipient`.
    /// @param erc20 An ERC-20 compliant token contract.
    /// @param owner The owner of an ERC-20 balance on the `erc20` contract
    ///        that's previously approved `ApprovalTarget` for at least `amount`.
    ///        Must match the recovered address of the included signature.
    /// @param recipient The recipient of the token transfer. Note that this
    ///        address hasn't been attested by a signature from `owner`, and is
    ///        instead chosen by `msg.sender`, attested in the signature as
    ///        `spender`
    /// @param amount The amount of `erc20` tokens to transfer from `owner` to
    ///        `recipient` using the base unit of the token, agnostic of the
    ///        token's decimal precision.
    /// @param deadline A timestamp deadline that must be after block.timestamp
    ///        to ensure execution. Deadlines of `type(uint256).max` effectively
    ///        never expire
    /// @param v The parity bit of an ECDSA signature on secp256k1. The
    ///        signature should authorize the movement of tokens from `owner` by
    ///        `msg.sender`, following the EIP-712 typehash. Must be either 27
    ///        or 28.
    /// @param r The r component of an ECDSA signature on secp256k1. The
    ///        signature should authorize the movement of tokens from `owner` by
    ///        `spender`, following the EIP-712 typehash.
    /// @param s The s component of an ECDSA signature on secp256k1. The
    ///        signature should authorize the movement of tokens from `owner` by
    ///        `spender`, following the EIP-712 typehash.
    /// @dev Requirements:
    ///      - `owner` must not be the 0 address
    ///      - `owner` must have approved `ApprovalTarget` to spend at least
    ///        `amount` of `erc20`
    ///      - `owner` must have a balance of at least `amount` on `erc20`
    ///      - `msg.sender` must be the same as `spender` in the provided
    ///        signature
    ///      - all preconditions for transfer on the `erc20` contract address
    ///        must additionally be satisfied
    function permitAndTransferFrom(
        address erc20,
        address owner,
        address recipient,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override nonReentrant {
        /* solhint-disable-next-line not-rely-on-time */
        require(deadline >= block.timestamp, "Permission expired");

        uint256 nonce = nonces[owner]++;

        bytes32 structHash = keccak256(
            abi.encode(PERMIT_AND_TRANSFER_FROM_TYPEHASH, erc20, owner, recipient, amount, nonce, deadline)
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        // @note ECDSA wrapper revert if signer is equal to address(0)
        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "Invalid signature");

        IERC20(erc20).safeTransferFrom(owner, recipient, amount);
    }
}
