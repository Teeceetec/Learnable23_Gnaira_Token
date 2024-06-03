// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {Gnaira} from "../src/Gnaira.sol";

contract DeployGnaira is Script {
    address[] public owners = [
       0x4293e94b9F43e00662AA138e9294507815D5f768,
       0x538d08Cb58cBfB08C2BE14A8D79092bbC6D981b4
    ];

    uint256 public constant required = 2;

    function run() public returns (Gnaira) {
        vm.startBroadcast();
        Gnaira gnaira = new Gnaira(owners, required);
        vm.stopBroadcast();

        return gnaira;
    }
}
