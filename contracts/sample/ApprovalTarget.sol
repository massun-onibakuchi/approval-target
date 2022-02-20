// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// abstract contract EIP712Helper {
//     uint256 public immutable cachedChainId;
//     bytes32 public immutable cachedDomainSeparator;

//     constructor() {
//         cachedChainId = block.chainid;
//         cachedDomainSeparator = buildDomainSeparator();
//     }

//     function getName() internal view virtual returns (string memory);

//     function getVersionString() internal view virtual returns (string memory);

//     /**
//      * @notice
//      * @param typeHashDigest TODO
//      * @param v The parity bit of an ECDSA signature on secp256k1. The
//      *        signature should authorize the movement of tokens from `owner` by
//      *        `msg.sender`, following the EIP-712 typehash. Must be either 27
//      *        or 28.
//      * @param r The r component of an ECDSA signature on secp256k1. The
//      *        signature should authorize the movement of tokens from `owner` by
//      *        `spender`, following the EIP-712 typehash.
//      * @param s The s component of an ECDSA signature on secp256k1. The
//      *        signature should authorize the movement of tokens from `owner` by
//      *        `spender`, following the EIP-712 typehash.
//      */
//     function recoverFromTypeHashSignature(
//         bytes32 typeHashDigest,
//         uint8 v,
//         bytes32 r,
//         bytes32 s
//     ) public view returns (address) {
//         // Only signatures with `s` value in the lower half of the secp256k1
//         // curve's order and `v` value of 27 or 28 are considered valid.
//         require(
//             uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
//             "Invalid signature 's' value"
//         );
//         require(v == 27 || v == 28, "Invalid signature 'v' value");

//         bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), typeHashDigest));

//         return ecrecover(digest, v, r, s);
//     }

//     /**
//      * @notice Returns hash of EIP712 Domain struct with the contract name as
//      *         a signing domain and the contract address as a verifying
//      *         contract.
//      *
//      *         Used to construct the EIP-712 PermitAndTransferFrom signature
//      *         provided to `permitAndTransferFrom` function.
//      * @dev The odd naming of this function is maintained for "mental
//      *      compatibility" with EIP-2612, which this mechanism resembles.
//      */
//     // solhint-disable-next-line func-name-mixedcase
//     function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
//         // As explained in EIP-2612, if the DOMAIN_SEPARATOR contains the
//         // chainId and is defined at contract deployment instead of
//         // reconstructed for every signature, there is a risk of possible replay
//         // attacks between chains in the event of a future chain split.
//         // To address this issue, we check the cached chain ID against the
//         // current one and in case they are different, we build domain separator
//         // from scratch.
//         if (block.chainid == cachedChainId) {
//             return cachedDomainSeparator;
//         } else {
//             return buildDomainSeparator();
//         }
//     }

//     function buildDomainSeparator() internal view virtual returns (bytes32) {
//         return
//             keccak256(
//                 abi.encode(
//                     keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
//                     keccak256(bytes(getName())),
//                     keccak256(bytes(getVersionString())),
//                     block.chainid,
//                     address(this)
//                 )
//             );
//     }
// }

// interface IApprovalTarget {
//     function permitAndTransferFrom(
//         address erc20,
//         address owner,
//         address recipient,
//         uint256 amount,
//         uint256 deadline,
//         uint8 v,
//         bytes32 r,
//         bytes32 s
//     ) external;
// }

// /// @notice ApprovalTarget is an immutable contract that accepts token approvals
// ///         from users across various ERC-20s, then enables anyone with a valid
// ///         user signature to transfer those tokens. You can think of it like
// ///         monkeypatching EIP-2612 support on all ERC-20 compliant tokens.
// ///
// ///         The more users that approve ApprovalTarget, and the dApps that
// ///         implement `permitAndTransferFrom`, the less users will have to
// ///         suffer the awful double-tx approve and spend UX.
// contract ApprovalTarget is EIP712Helper, ReentrancyGuard, IApprovalTarget {
//     using SafeERC20 for IERC20;

//     mapping(address => uint256) public nonces;

//     // solhint-disable-next-line no-empty-blocks
//     constructor() EIP712Helper() {}

//     /// @notice Returns EIP-712 PermitAndTransferFrom message typehash. Used to
//     ///         construct the EIP2612-inspired signature provided to
//     ///         `permitAndTransferFrom` function.
//     bytes32 public constant PERMIT_AND_TRANSFER_FROM_TYPEHASH =
//         keccak256(
//             "PermitAndTransferFrom(address erc20,address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
//         );

//     function getVersionString() internal view virtual override returns (string memory) {
//         return "1";
//     }

//     function getName() internal view virtual override returns (string memory) {
//         return "ApprovalTarget";
//     }

//     /// @notice Given a pre-existing approval from `owner` to this contract,
//     ///         and a valid secp265k1 signature authorizing the move by
//     ///         `msg.sender`, transfer `amount` tokens in the `erc20` token
//     ///         contract from `owner` to `recipient`.
//     /// @param erc20 An ERC-20 compliant token contract.
//     /// @param owner The owner of an ERC-20 balance on the `erc20` contract
//     ///        that's previously approved `ApprovalTarget` for at least `amount`.
//     ///        Must match the recovered address of the included signature.
//     /// @param recipient The recipient of the token transfer. Note that this
//     ///        address hasn't been attested by a signature from `owner`, and is
//     ///        instead chosen by `msg.sender`, attested in the signature as
//     ///        `spender`
//     /// @param amount The amount of `erc20` tokens to transfer from `owner` to
//     ///        `recipient` using the base unit of the token, agnostic of the
//     ///        token's decimal precision.
//     /// @param deadline A timestamp deadline that must be after block.timestamp
//     ///        to ensure execution. Deadlines of `type(uint256).max` effectively
//     ///        never expire
//     /// @param v The parity bit of an ECDSA signature on secp256k1. The
//     ///        signature should authorize the movement of tokens from `owner` by
//     ///        `msg.sender`, following the EIP-712 typehash. Must be either 27
//     ///        or 28.
//     /// @param r The r component of an ECDSA signature on secp256k1. The
//     ///        signature should authorize the movement of tokens from `owner` by
//     ///        `spender`, following the EIP-712 typehash.
//     /// @param s The s component of an ECDSA signature on secp256k1. The
//     ///        signature should authorize the movement of tokens from `owner` by
//     ///        `spender`, following the EIP-712 typehash.
//     /// @dev Requirements:
//     ///      - `owner` must not be the 0 address
//     ///      - `owner` must have approved `ApprovalTarget` to spend at least
//     ///        `amount` of `erc20`
//     ///      - `owner` must have a balance of at least `amount` on `erc20`
//     ///      - `msg.sender` must be the same as `spender` in the provided
//     ///        signature
//     ///      - all preconditions for transfer on the `erc20` contract address
//     ///        must additionally be satisfied
//     function permitAndTransferFrom(
//         address erc20,
//         address owner,
//         address recipient,
//         uint256 amount,
//         uint256 deadline,
//         uint8 v,
//         bytes32 r,
//         bytes32 s
//     ) external virtual override nonReentrant {
//         /* solhint-disable-next-line not-rely-on-time */
//         require(deadline >= block.timestamp, "Permission expired");

//         uint256 nonce = nonces[owner]++;

//         bytes32 typeHashDigest = keccak256(
//             abi.encode(PERMIT_AND_TRANSFER_FROM_TYPEHASH, erc20, owner, msg.sender, amount, nonce, deadline)
//         );

//         address signer = recoverFromTypeHashSignature(typeHashDigest, v, r, s);

//         require(signer != address(0) && signer == owner, "Invalid signature");

//         IERC20(erc20).safeTransferFrom(owner, recipient, amount);
//     }
// }
