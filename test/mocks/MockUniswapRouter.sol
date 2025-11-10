// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockUniswapRouter {
    address public WETH;

    constructor(address _weth) {
        WETH = _weth;
    }

    function swapExactETHForTokens(
        uint, // amountOutMin
        address[] calldata path,
        address to,
        uint // deadline
    ) external payable returns (uint[] memory amounts) {
        require(path.length == 2, "Invalid path");
        require(path[1] != address(0), "Invalid USDC");

        amounts = new uint[](2);
        amounts[0] = msg.value;
        amounts[1] = 1000e6; // Simula 1 ETH = 1000 USDC

        require(IERC20(path[1]).transfer(to, amounts[1]), "Mock transfer failed");

        return amounts;
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint, // amountOutMin
        address[] calldata path,
        address to,
        uint // deadline
    ) external returns (uint[] memory amounts) {
        require(path.length == 2, "Invalid path");
        require(path[1] != address(0), "Invalid USDC");

        amounts = new uint[](2);
        amounts[0] = amountIn;
        amounts[1] = 1000e6;

        require(IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn), "Mock transferFrom failed");
        require(IERC20(path[1]).transfer(to, amounts[1]), "Mock transfer failed");

        return amounts;
    }

    // Stubbed functions (no-op)
    function getAmountsOut(uint amountIn) external pure returns (uint[] memory) {
        uint[] memory out = new uint[](2);
        out[0] = amountIn;
        out[1] = amountIn * 2;
        return out;
    }

    receive() external payable {}
}