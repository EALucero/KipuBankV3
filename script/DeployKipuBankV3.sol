// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "forge-std/Script.sol";
import "../src/KipuBankV3.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployKipuBankV3 is Script {
    function run() external {
        // Cargar clave privada desde .env
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Parámetros de despliegue
        address usdc = vm.envAddress("USDC_ADDRESS");
        address permit2 = vm.envAddress("PERMIT2_ADDRESS");
        address universalRouter = vm.envAddress("UNIVERSAL_ROUTER");
        address uniswapRouter = vm.envAddress("UNISWAP_ROUTER");
        uint256 bankCap = vm.envUint("BANK_CAP_USDC");
        uint256 withdrawalLimit = vm.envUint("WITHDRAWAL_LIMIT_USDC");

        vm.startBroadcast(deployerPrivateKey);

        KipuBankV3 kipu = new KipuBankV3(
            usdc,
            permit2,
            universalRouter,
            uniswapRouter,
            bankCap,
            withdrawalLimit
        );

        vm.stopBroadcast();

        console.log("KipuBankV3 deployed at:", address(kipu));
    }
}