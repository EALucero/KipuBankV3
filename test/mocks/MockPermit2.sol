// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import { PermitTransferFrom, SignatureTransferDetails } from "../../utils/permitStruct.sol";
import { IPermit2 } from "../../utils/IPermit2.sol";

contract MockPermit2 is IPermit2 {
    event PermitUsed(address indexed user, bytes data);
    event TransferSimulated(address indexed from, address indexed to, uint256 amount);

    function permit(bytes calldata data) external {
        emit PermitUsed(msg.sender, data);
    }

    function permitTransferFrom(
        PermitTransferFrom calldata permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external override {
        // Simulamos la transferencia del token
        emit TransferSimulated(owner, transferDetails.to, transferDetails.requestedAmount);
    }
}