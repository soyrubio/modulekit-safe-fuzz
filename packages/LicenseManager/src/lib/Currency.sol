// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20Minimal } from "../interfaces/external/IERC20Minimal.sol";
import { ERC7579Execution } from "./ERC7579Execution.sol";
import "forge-std/console2.sol";

type Currency is address;

using {
    greaterThan as >,
    lessThan as <,
    greaterThanOrEqualTo as >=,
    equals as ==
} for Currency global;

function equals(Currency currency, Currency other) pure returns (bool) {
    return Currency.unwrap(currency) == Currency.unwrap(other);
}

function greaterThan(Currency currency, Currency other) pure returns (bool) {
    return Currency.unwrap(currency) > Currency.unwrap(other);
}

function lessThan(Currency currency, Currency other) pure returns (bool) {
    return Currency.unwrap(currency) < Currency.unwrap(other);
}

function greaterThanOrEqualTo(Currency currency, Currency other) pure returns (bool) {
    return Currency.unwrap(currency) >= Currency.unwrap(other);
}

/// @title CurrencyLibrary
/// @dev This library allows for transferring and holding native tokens and ERC20 tokens
library CurrencyLibrary {
    using CurrencyLibrary for Currency;
    using ERC7579Execution for address;

    /// @notice Thrown when a native transfer fails
    error NativeTransferFailed();

    error InvalidCurrency();

    /// @notice Thrown when an ERC20 transfer fails
    error ERC20TransferFailed();

    Currency public constant NATIVE =
        Currency.wrap(address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE));

    function transfer(Currency currency, address to, uint256 amount) internal {
        // implementation from
        // https://github.com/transmissions11/solmate/blob/e8f96f25d48fe702117ce76c79228ca4f20206cb/src/utils/SafeTransferLib.sol

        bool success;
        if (currency.isZero()) {
            revert InvalidCurrency();
        } else if (currency.isNative()) {
            assembly {
                // Transfer the ETH and store if it succeeded or not.
                success := call(gas(), to, amount, 0, 0, 0, 0)
            }

            if (!success) revert NativeTransferFailed();
        } else {
            assembly {
                // We'll write our calldata to this slot below, but restore it later.
                let memPointer := mload(0x40)

                // Write the abi-encoded calldata into memory, beginning with the function selector.
                mstore(0, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
                mstore(4, to) // Append the "to" argument.
                mstore(36, amount) // Append the "amount" argument.

                success :=
                    and(
                        // Set success to whether the call reverted, if not we check it either
                        // returned exactly 1 (can't just be non-zero data), or had no return data.
                        or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                        // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                        // Counterintuitively, this call() must be positioned after the or() in the
                        // surrounding and() because and() evaluates its arguments from right to left.
                        call(gas(), currency, 0, 0, 68, 0, 32)
                    )

                mstore(0x60, 0) // Restore the zero slot to zero.
                mstore(0x40, memPointer) // Restore the memPointer.
            }

            if (!success) revert ERC20TransferFailed();
        }
    }

    function balanceOfSelf(Currency currency) internal view returns (uint256) {
        if (currency.isNative()) {
            return address(this).balance;
        } else {
            return IERC20Minimal(Currency.unwrap(currency)).balanceOf(address(this));
        }
    }

    function balanceOf(Currency currency, address owner) internal view returns (uint256) {
        if (currency.isNative()) {
            return owner.balance;
        } else {
            return IERC20Minimal(Currency.unwrap(currency)).balanceOf(owner);
        }
    }

    function transferOrApprove(Currency currency, address account, uint256 amount) internal {
        if (currency.isNative()) {
            account.execute({ to: address(this), value: amount, data: "" });
        } else {
            bool success = transferFrom(currency, account, amount);
            if (success) {
                return;
            } else {
                account.execute({
                    to: Currency.unwrap(currency),
                    value: 0,
                    data: abi.encodeWithSelector(IERC20Minimal.approve.selector, address(this), amount)
                });
                safeTransferFrom(currency, account, amount);
            }
        }
    }

    function transferFrom(
        Currency currency,
        address owner,
        uint256 amount
    )
        internal
        returns (bool success)
    {
        address to = address(this);

        if (currency.isZero()) {
            revert InvalidCurrency();
        } else {
            assembly {
                // We'll write our calldata to this slot below, but restore it later.
                let memPointer := mload(0x40)

                // Write the abi-encoded calldata into memory, beginning with the function selector.
                mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
                mstore(4, owner) // Append the "from" argument.
                mstore(36, to) // Append the "to" argument.
                mstore(68, amount) // Append the "amount" argument.

                success :=
                    and(
                        // Set success to whether the call reverted, if not we check it either
                        // returned exactly 1 (can't just be non-zero data), or had no return data.
                        or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                        // We use 100 because that's the total length of our calldata (4 + 32 * 3)
                        // Counterintuitively, this call() must be positioned after the or() in the
                        // surrounding and() because and() evaluates its arguments from right to left.
                        call(gas(), currency, 0, 0, 100, 0, 32)
                    )

                mstore(0x60, 0) // Restore the zero slot to zero.
                mstore(0x40, memPointer) // Restore the memPointer.
            }
        }
    }

    function safeTransferFrom(Currency currency, address owner, uint256 amount) internal {
        bool success;

        address to = address(this);

        if (currency.isZero()) {
            revert InvalidCurrency();
        } else {
            assembly {
                // We'll write our calldata to this slot below, but restore it later.
                let memPointer := mload(0x40)

                // Write the abi-encoded calldata into memory, beginning with the function selector.
                mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
                mstore(4, owner) // Append the "from" argument.
                mstore(36, to) // Append the "to" argument.
                mstore(68, amount) // Append the "amount" argument.

                success :=
                    and(
                        // Set success to whether the call reverted, if not we check it either
                        // returned exactly 1 (can't just be non-zero data), or had no return data.
                        or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                        // We use 100 because that's the total length of our calldata (4 + 32 * 3)
                        // Counterintuitively, this call() must be positioned after the or() in the
                        // surrounding and() because and() evaluates its arguments from right to left.
                        call(gas(), currency, 0, 0, 100, 0, 32)
                    )

                mstore(0x60, 0) // Restore the zero slot to zero.
                mstore(0x40, memPointer) // Restore the memPointer.
            }

            if (!success) revert ERC20TransferFailed();
        }
    }

    function isNative(Currency currency) internal pure returns (bool) {
        return Currency.unwrap(currency) == Currency.unwrap(NATIVE);
    }

    function toId(Currency currency) internal pure returns (uint256) {
        return uint160(Currency.unwrap(currency));
    }

    function isZero(Currency currency) internal pure returns (bool) {
        return Currency.unwrap(currency) == address(0);
    }

    function fromId(uint256 id) internal pure returns (Currency) {
        return Currency.wrap(address(uint160(id)));
    }
}