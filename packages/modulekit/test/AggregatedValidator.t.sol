// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./MakeAccount.t.sol";

contract AggregatedValidator is BaseTest {
    using ModuleKitHelpers for AccountInstance;

    function setUp() public {
        super.setUp();

        instance.installModule({
            moduleTypeId: MODULE_TYPE_VALIDATOR,
            module: newValidator1,
            data: ""
        });
    }

    function test_aggregate() public { }
}
