// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import { SafeERC7579 } from "src/SafeERC7579.sol";
import { ModuleManager } from "src/core/ModuleManager.sol";
import { Bootstrap } from "src/utils/Bootstrap.sol";
import { MockValidator } from "./mocks/MockValidator.sol";
import { ISafe } from "src/interfaces/ISafe.sol";
import { MockExecutor } from "./mocks/MockExecutor.sol";
import { MockFallback } from "./mocks/MockFallback.sol";
import { MockTarget } from "@rhinestone/modulekit/src/mocks/MockTarget.sol";

import { Safe } from "@safe-global/safe-contracts/contracts/Safe.sol";
import { LibClone } from "solady/src/utils/LibClone.sol";

import "./dependencies/EntryPoint.sol";

contract TestBaseUtil is Test {
    // singletons
    SafeERC7579 internal safe7579;
    Safe internal safeImpl;
    Safe internal safe;
    IEntryPoint internal entrypoint = IEntryPoint(ENTRYPOINT_ADDR);

    MockValidator internal defaultValidator;
    MockExecutor internal defaultExecutor;
    Bootstrap internal bootstrap;

    MockTarget internal target;

    Account internal signer1;
    Account internal signer2;

    function setUp() public virtual {
        // Set up EntryPoint
        etchEntrypoint();

        // Set up MSA and Factory
        bootstrap = new Bootstrap();
        safe7579 = new SafeERC7579();
        vm.label(address(safe7579), "safe7579");
        safeImpl = new Safe();

        signer1 = makeAccount("signer1");
        signer2 = makeAccount("signer2");

        // Set up Modules
        defaultExecutor = new MockExecutor();
        defaultValidator = new MockValidator();

        // Set up Target for testing
        target = new MockTarget();

        (safe,) = safeSetup();
        vm.deal(address(safe), 100 ether);
    }

    function safeSetup() internal returns (Safe _safeAccount, address _defaultValidator) {
        _safeAccount = Safe(payable(LibClone.clone(address(safeImpl))));
        vm.label(address(_safeAccount), "Safe Account");
        _defaultValidator = address(defaultValidator);

        address[] memory signers = new address[](2);
        signers[0] = signer1.addr;
        signers[1] = signer2.addr;

        _safeAccount.setup({
            _owners: signers,
            _threshold: 2,
            to: address(bootstrap),
            data: abi.encodeCall(
                Bootstrap.enableModule,
                (address(safe7579), _defaultValidator, "", address(defaultExecutor), "")
                ),
            fallbackHandler: address(safe7579),
            paymentToken: address(0), // optional payment token
            payment: 0,
            paymentReceiver: payable(address(0)) // optional payment receiver
         });
    }

    function getNonce(address account, address validator) internal view returns (uint256 nonce) {
        uint192 key = uint192(bytes24(bytes20(address(validator))));
        nonce = entrypoint.getNonce(address(account), key);
    }

    function getDefaultUserOp() internal pure returns (PackedUserOperation memory userOp) {
        userOp = PackedUserOperation({
            sender: address(0),
            nonce: 0,
            initCode: "",
            callData: "",
            accountGasLimits: bytes32(abi.encodePacked(uint128(2e6), uint128(2e6))),
            preVerificationGas: 2e6,
            gasFees: bytes32(abi.encodePacked(uint128(2e6), uint128(2e6))),
            paymasterAndData: bytes(""),
            signature: abi.encodePacked(hex"41414141")
        });
    }
}
