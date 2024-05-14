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

# Print failing tx call trace
# def revert_handler(e: TransactionRevertedError):
#     if e.tx is not None:
#         print(e.tx.call_trace)

ENTRYPOINT_ADDR = 0x0000000071727De22E5E9d8BAf0edAc6f37da032

def etch(_address: Account, _code: bytes):
    _address.code = _code

def mock_entrypoint():
    _entrypoint_code = EntryPointSimulationsPatch.deploy().code
    etch(ENTRYPOINT_ADDR, _entrypoint_code)
    _entrypoint = EntryPointSimulationsPatch(ENTRYPOINT_ADDR)
    _entrypoint.init()
    return _entrypoint

class Safe7579Fuzz(FuzzTest):
    entrypoint: EntryPointSimulationsPatch

    def __init__(self) -> None:
        super().__init__()

    def deploy_contracts(self) -> None:
        _signers = [
            default_chain.accounts[0],
            default_chain.accounts[1],
            default_chain.accounts[2]
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
                module=_default_executor,
                initData=bytearray("")
            )
        ]
        _validators = [
            ModuleInit(
                module=_default_validator,
                initData=bytearray("")
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

        # TODO why this
        _calldata = Abi.encode_call(
            IERC7579Account.execute,
            [
                ModeLibWrapper.deploy().encodeSimpleSingle(),
                ExecutionLibWrapper.deploy().encodeSingle(
                    target=_target,
                    value=0,
                    callData=Abi.encode_call(
                        MockTarget.set,
                        [1337]
                    )
                )
            ]
        )
        _initData = Safe7579Launchpad.InitData(
            singleton=self.safe_singleton,
            owners=[default_chain.accounts[0], default_chain.accounts[1], default_chain.accounts[2]],
            threshold=_threshold,
            setupTo=self.launchpad,
            setupData=_setupdata,
            safe7579=self.safe7579_singleton,
            validators=_validators,
            callData=_calldata
        )

        _initHash = self.launchpad.hash(_initData)
        self.safe_factory.createProxyWithNonce(
            self.launchpad,
            Abi.encode_call(
                Safe7579Launchpad.preValidationSetup,
                [_initHash, Address(0), ""]
            )
        )
        self.safe = self.safe_factory.deploy_new(
            [default_chain.accounts[0], default_chain.accounts[1], default_chain.accounts[2]],
            2,
            0
        )

        self.safe_factory.createProxyWithNonce(


    def pre_sequence(self) -> None:
        singleon

