// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Script } from "forge-std/Script.sol";
import { Safe7579 } from "src/Safe7579.sol";
import { Safe7579Launchpad } from "src/Safe7579Launchpad.sol";
import { IERC7484 } from "src/interfaces/IERC7484.sol";

/**
 * @title Deploy
 * @author @kopy-kat
 */
contract DeployScript is Script {
    function run() public {
        bytes32 salt = bytes32(uint256(0));

        address entryPoint = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;
        IERC7484 registry = IERC7484(0x1D8c40F958Fb6998067e9B8B26850d2ae30b7c70);

        vm.startBroadcast(vm.envUint("PK"));

        new Safe7579{ salt: salt }();
        new Safe7579Launchpad{ salt: salt }(entryPoint, registry);

        vm.stopBroadcast();
    }
}
