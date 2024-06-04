pragma solidity ^0.8.23;

import "test/dependencies/EntryPoint.sol";
import "test/mocks/MockRegistry.sol";
import "test/mocks/MockValidator.sol";
import "test/mocks/MockTarget.sol";
import "test/mocks/MockExecutor.sol";
import { ModeLib, ModeCode } from "erc7579/lib/ModeLib.sol";
import { ExecutionLib } from "erc7579/lib/ExecutionLib.sol";
import {
    SafeProxy,
    SafeProxyFactory
} from "@safe-global/safe-contracts/contracts/proxies/SafeProxyFactory.sol";

contract ModeLibWrapper {
    function encodeSimpleSingle() external pure returns (ModeCode) {
        return ModeLib.encodeSimpleSingle();
    }
}

contract ExecutionLibWrapper {
    function encodeSingle(
        address target,
        uint256 value,
        bytes memory callData
    )
        external
        pure
        returns (bytes memory)
    {
        return ExecutionLib.encodeSingle(target, value, callData);
    }
}

contract Cast {
    function bytes32ToUint256(bytes32 b) external pure returns (uint256) {
        return uint256(b);
    }
}