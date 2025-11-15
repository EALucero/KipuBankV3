// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import { MockUSDC } from "../test/mocks/MockUSDC.sol";

contract MintUSDC is Script {
    function run() external {
        address usdcAddress = vm.envAddress("USDC_ADDRESS");
        address recipient = vm.envAddress("RECIPIENT");
        uint256 amount = vm.envUint("MINT_AMOUNT");

        vm.startBroadcast();
        MockUSDC(usdcAddress).mint(recipient, amount);
        console.log("✅ USDC minted to:", recipient);
        vm.stopBroadcast();
    }
}