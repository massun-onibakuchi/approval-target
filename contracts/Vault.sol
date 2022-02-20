// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

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

/// @title an Minimal interace DeFi dapp vault : Yield Bearing Vault Standard https://eips.ethereum.org/EIPS/eip-4626
/// @notice Users deposit their tokens to this vault.
interface IVault {
    function asset() external view returns (IERC20);

    function deposit(address to, uint256 amount) external;

    function depositBySig(
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

/// @title an mimimal implementation of DeFi dapp vault
/// @notice Users deposit their tokens to this vault.
contract Vault is IVault {
    using SafeERC20 for IERC20;
    /// @notice an immutable contract that accepts token approvals
    ///         from users across various ERC-20s, then enables anyone with a valid
    ///         user signature to transfer those tokens. You can think of it like
    ///         monkeypatching EIP-2612 support on all ERC-20 compliant tokens.
    IApprovalTarget public immutable approvalTarget;

    /// @notice ERC20 underlying token to be deposited
    IERC20 public immutable override asset;

    constructor(IApprovalTarget _approvalTarget, IERC20 _asset) {
        approvalTarget = _approvalTarget;
        asset = _asset;
    }

    /// @notice deposit `amount` of tokens to vault
    ///         users have to approve this contract before calling this function
    /// @param amount of underlying tokens
    function deposit(address to, uint256 amount) external override {
        asset.safeTransferFrom(msg.sender, address(this), amount);

        // do something
    }

    /// @notice deposit `amount` of tokens to vault by using
    ///         users have to sign before calling this function
    function depositBySig(
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        approvalTarget.permitAndTransferFrom(
            address(asset),
            msg.sender, // owner
            address(this), // spender
            amount,
            deadline,
            v,
            r,
            s
        );
        // asset.permit(msg.sender, address(this), amount, deadline, v, r, s);

        /// do something
    }
}
