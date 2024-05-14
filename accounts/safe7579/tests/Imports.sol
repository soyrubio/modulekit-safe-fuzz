pragma solidity ^0.8.23;

import "test/dependencies/EntryPoint.sol";
import "test/mocks/MockRegistry.sol";
import "test/mocks/MockValidator.sol";
import "test/mocks/MockTarget.sol";
import "test/mocks/MockExecutor.sol";
import { ModeLib, ModeCode } from "erc7579/lib/ModeLib.sol";
import { ExecutionLib } from "erc7579/lib/ExecutionLib.sol";

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