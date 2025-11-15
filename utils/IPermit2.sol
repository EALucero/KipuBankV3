// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { PermitTransferFrom, SignatureTransferDetails } from "./permitStruct.sol";

interface IPermit2 {
    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails memory transferDetails,
        address owner,
        bytes memory signature
    ) external;
}