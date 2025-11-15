// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import { KipuBankV3 } from "../src/KipuBankV3.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract InteractKipuBankV3 is Script {
    function run() external {
        address payable kipuAddress = payable(vm.envAddress("KIPU_ADDRESS"));
        address usdcAddress = vm.envAddress("USDC_ADDRESS");
        uint256 depositUsdcAmount = vm.envUint("DEPOSIT_USDC");
        uint256 depositEthAmount = vm.envUint("DEPOSIT_ETH");
        uint256 withdrawUsdcAmount = vm.envUint("WITHDRAW_USDC");

        vm.startBroadcast();

        KipuBankV3 kipu = KipuBankV3(kipuAddress);
        IERC20 usdc = IERC20(usdcAddress);

        // 1. Depositar USDC
        usdc.approve(kipuAddress, depositUsdcAmount);
        kipu.deposit(usdcAddress, depositUsdcAmount);
        console.log("USDC depositado:", depositUsdcAmount);

        // 2. Depositar ETH
        kipu.deposit{value: depositEthAmount}(address(0), depositEthAmount);
        console.log("ETH depositado:", depositEthAmount);

        // 3. Retirar USDC (respetando el límite)
        kipu.withdraw(withdrawUsdcAmount);
        console.log("USDC retirado:", withdrawUsdcAmount);

        vm.stopBroadcast();
    }
}