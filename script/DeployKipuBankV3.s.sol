// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import { KipuBankV3 } from "../src/KipuBankV3.sol";
import { console } from "forge-std/console.sol";

contract DeployKipuBankV3 is Script {
    function run() external {
        vm.startBroadcast();

        address usdc = vm.envAddress("USDC_ADDRESS");
        address permit2 = vm.envAddress("PERMIT2_ADDRESS");
        address universalRouter = vm.envAddress("UNIVERSAL_ROUTER");
        address uniswapRouter = vm.envAddress("UNISWAP_ROUTER");
        uint256 bankCapUsdc = vm.envUint("BANK_CAP_USDC");
        uint256 withdrawalLimitUsdc = vm.envUint("WITHDRAWAL_LIMIT_USDC");

        KipuBankV3 bank = new KipuBankV3(
            usdc,
            permit2,
            universalRouter,
            uniswapRouter,
            bankCapUsdc,
            withdrawalLimitUsdc
        );

        console.log("KipuBankV3 deployed at:", address(bank));

        vm.stopBroadcast();
    }
}