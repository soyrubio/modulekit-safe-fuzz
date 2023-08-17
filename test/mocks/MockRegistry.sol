// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IRegistry} from "../../src/auxiliary/interfaces/IRegistry.sol";

/// @title MockRegistry
/// @author zeroknots
contract MockRegistry is IRegistry {
    function check(address plugin, address trustedAuthority) external view override returns (uint48, uint48) {
        return (uint48(123_455), uint48(0));
    }
}