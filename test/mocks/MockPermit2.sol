// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

contract MockPermit2 {
    event PermitUsed(address indexed user, bytes data);

    function permit(bytes calldata data) external {
        emit PermitUsed(msg.sender, data);
        // No hace nada, solo simula que se usó Permit2
    }
}