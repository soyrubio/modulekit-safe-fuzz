// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { ModuleManager } from "src/core/ModuleManager.sol";
import { ISafe } from "src/interfaces/ISafe.sol";
import { SafeERC7579 } from "src/SafeERC7579.sol";

contract Bootstrap is ModuleManager {
    function enableModule(
        address bootstrap,
        address safe7579,
        address validator,
        bytes calldata validatorData,
        address executor,
        bytes calldata executorData
    )
        external
    {
        // init validator
        ISafe(address(this)).enableModule(safe7579);

        bytes memory initCalldata = abi.encodeWithSelector(
            this.initSafe7579.selector, validator, validatorData, executor, executorData
        );
        SafeERC7579(payable(safe7579)).initializeAccount(
            abi.encode(address(bootstrap), initCalldata)
        );
    }

    function initSafe7579(
        address validator,
        bytes calldata validatorData,
        address executor,
        bytes calldata executorData
    )
        external
    {
        _installValidator(address(validator), validatorData);
        _installExecutor(executor, executorData);
    }
}
