from wake.testing import *
from wake.testing.fuzzing import *
from wake_safe import *
from pytypes.src.DataTypes import ModuleInit
from pytypes.src.Safe7579 import Safe7579
from pytypes.src.Safe7579Launchpad import Safe7579Launchpad
from pytypes.src.lib.ModeLib import ModeLib
from pytypes.test.dependencies.EntryPoint import EntryPointSimulationsPatch
from pytypes.test.mocks.MockRegistry import MockRegistry
from pytypes.test.mocks.MockValidator import MockValidator
from pytypes.test.mocks.MockExecutor import MockExecutor
from pytypes.test.mocks.MockTarget import MockTarget
from pytypes.src.interfaces.IERC7579Account import IERC7579Account
from pytypes.tests.Imports import ModeLibWrapper, ExecutionLibWrapper
from pytypes.node_modules.safeglobal.safecontracts.contracts.proxies.SafeProxy import SafeProxy
from pytypes.node_modules.ERC4337.accountabstraction.contracts.interfaces.PackedUserOperation import PackedUserOperation

# Print failing tx call trace
# def revert_handler(e: TransactionRevertedError):
#     if e.tx is not None:
#         print(e.tx.call_trace)

ENTRYPOINT_ADDR: Account = Account(address="0x0000000071727De22E5E9d8BAf0edAc6f37da032")

def etch(account: Account, code: bytes):
    account.code = code

def mock_entrypoint():
    _entrypoint_code = EntryPointSimulationsPatch.deploy().code
    etch(ENTRYPOINT_ADDR, _entrypoint_code)
    _entrypoint = EntryPointSimulationsPatch(ENTRYPOINT_ADDR)
    _entrypoint.init(ENTRYPOINT_ADDR) # TODO why?
    return _entrypoint

# TODO whats this



class Safe7579Fuzz(FuzzTest):
    entrypoint: EntryPointSimulationsPatch

    def get_default_userop(
            self,
            account: Address,
            validator: Address,
        ):
        return PackedUserOperation(
            sender=account,
            nonce=self.safe7579_singleton.getNonce(account, validator),
            initCode=bytearray(),
            callData=bytearray(),
            accountGasLimits=bytearray(Abi.encode_packed(['uint128', 'uint128'], [2e6, 2e6])),
            preVerificationGas=int(2e6),
            gasFees=bytearray(Abi.encode_packed(['uint128', 'uint128'], [2e6, 2e6])),
            paymasterAndData=bytearray(),
            signature=bytearray(Abi.encode_packed(['bytes'], [bytearray(0x41414141)]))
        )

    def get_initcode(self, initializer: bytes, salt: bytes) -> bytes:
        return Abi.encode_packed(
            ['address', 'bytes'],
            [
                self.safe_factory.address,
                Abi.encode_call(
                    self.safe_factory.createProxyWithNonce,
                    [self.launchpad.address, initializer, salt]
                )
            ]
        )

    def __init__(self) -> None:
        super().__init__()

    @flow()
    def deploy_contracts(self) -> None:
        _salt = bytes32(0) # TODO what is this
        _owners: List[Address] = [
            default_chain.accounts[0].address,
            default_chain.accounts[1].address,
            default_chain.accounts[2].address
        ]
        _attesters = [
            default_chain.accounts[3],
            default_chain.accounts[4]
        ]
        _threshold = 2
        _threshold_registry = 2

        self.entrypoint = mock_entrypoint()

        self.registry = MockRegistry.deploy()
        self.launchpad = Safe7579Launchpad.deploy(self.entrypoint, self.registry)

        # self.safe_factory = SafeFactory()
        _factory = SafeFactory()
        self.safe_factory = _factory.safe_proxy_factory
        self.safe_singleton = _factory.safe_singleton
        self.safe7579_singleton = Safe7579.deploy()

        _target = MockTarget.deploy()

        _default_validator = MockValidator.deploy()
        _default_executor = MockExecutor.deploy()
        _executors = [
            ModuleInit(
                module=_default_executor.address,
                initData=bytearray()
            )
        ]
        _validators = [
            ModuleInit(
                module=_default_validator.address,
                initData=bytearray()
            )
        ]
        _hooks = []
        _fallbacks = []
        _setupdata = Abi.encode_call(
            Safe7579Launchpad.initSafe7579,
            [
                self.safe7579_singleton,
                _executors,
                _fallbacks,
                _hooks,
                _attesters,
                _threshold_registry
            ]
        )
        a = ExecutionLibWrapper.deploy().encodeSingle(
                    target=_target.address,
                    value_=0,
                    callData=Abi.encode_call(
                        MockTarget.set,
                        [1337]
                    )
        )

        # TODO why this
        _calldata = Abi.encode_call(
            IERC7579Account.execute,
            [
                ModeLibWrapper.deploy().encodeSimpleSingle(),
                ExecutionLibWrapper.deploy().encodeSingle(
                    target=_target.address,
                    value_=0,
                    callData=Abi.encode_call(
                        MockTarget.set,
                        [1337]
                    )
                )
            ]
        )

        _initdata = Safe7579Launchpad.InitData(
            singleton=self.safe_singleton.address,
            owners=_owners,
            threshold=_threshold,
            setupTo=self.launchpad.address,
            setupData=bytearray(_setupdata),
            safe7579=self.safe7579_singleton,
            validators=_validators,
            callData=bytearray(_calldata)
        )

        _initHash = self.launchpad.hash(_initdata)

        _factory_initializer = Abi.encode_call(
            Safe7579Launchpad.preValidationSetup,
            [_initHash, Address(0), ""]
        )

        _predicted_address = self.launchpad.predictSafeAddress(
            self.safe_singleton,
            self.safe_factory,
            SafeProxy.get_creation_code(),
            _salt,
            _factory_initializer
        )

        _userop = self.get_default_userop(
            account=self.safe_singleton.address,
            validator=_default_validator.address
        )

        _userop.callData = bytearray(Abi.encode_call(
            Safe7579Launchpad.setupSafe,
            [
                _initdata
            ]
        ))
        _userop.initCode = bytearray(self.get_initcode(
            initializer=_factory_initializer,
            salt=_salt
        ))
        _userop.sender = _predicted_address
        _userop.signature = bytearray(Abi.encode_packed(
            ['uint48', 'uint48', 'bytes'],
            [
                0,
                2**48 - 1, # max uint48
                bytearray(4141414141414141414141414141414141) # TODO why
            ]
        ))

        _userop_hash = self.entrypoint.getUserOpHash(_userop)

        _userops: List[PackedUserOperation] = [_userop]
        Account(_predicted_address).balance = int(1e18)

        _beneficiary = Address(0x69) # TODO why 69
        self.entrypoint.handleOps(
            _userops,
            _beneficiary,
        )

        safe: Safe = _factory.create_from_existing(_predicted_address)

        assert (_target.value() == 1337)

def revert_handler(e: TransactionRevertedError):
    if e.tx is not None:
        print(e.tx.call_trace)
        print(e.tx.console_logs)

@on_revert(revert_handler)
def test_custom_bridge():
    Safe7579Fuzz().run(sequences_count=1, flows_count=1)