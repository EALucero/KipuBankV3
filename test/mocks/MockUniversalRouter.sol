// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockUniversalRouter {
    address public usdc;
    uint256 public simulatedOutput;

    constructor(address _usdc) {
        usdc = _usdc;
        simulatedOutput = 1000e6; // 1000 USDC simulados
    }

    function execute(
        bytes calldata commands,
        bytes[] calldata inputs,
        uint256 deadline
    ) external {
        // Simula el swap depositando USDC en el contrato
        IERC20(usdc).transferFrom(msg.sender, address(this), simulatedOutput);
    }

    function setSimulatedOutput(uint256 amount) external {
        simulatedOutput = amount;
    }
}