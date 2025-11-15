// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import { Test } from "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { KipuBankV3 } from "../src/KipuBankV3.sol";
import { MockERC20 } from "./mocks/MockERC20.sol";
import { MockPermit2 } from "./mocks/MockPermit2.sol";
import { MockUniswapRouter } from "./mocks/MockUniswapRouter.sol";
import { MockUniversalRouter } from "./mocks/MockUniversalRouter.sol";
import { PermitTransferFrom, SignatureTransferDetails, TokenPermissions } from "../utils/permitStruct.sol";
import "forge-std/Vm.sol";
import { console } from "forge-std/console.sol";

contract KipuBankV3Test is Test {
    KipuBankV3 kipu;
    address usdc = address(0xA1);
    address user = address(0xC1);

    IERC20 usdcToken;
    MockERC20 mockUsdc;
    MockUniswapRouter uniswapRouter;
    MockUniversalRouter universalRouter;
    MockPermit2 permit2;

    function setUp() public {
        // Mocks
        mockUsdc = new MockERC20();
        permit2 = new MockPermit2();
        universalRouter = new MockUniversalRouter(address(mockUsdc));
        uniswapRouter = new MockUniswapRouter(address(0xEeeee));

        // Instancia del contrato
        kipu = new KipuBankV3(
            address(mockUsdc),
            address(permit2),
            address(universalRouter),
            address(uniswapRouter),
            1_000_000e6,
            10_000e6
        );

        // Etiquetas
        vm.label(address(mockUsdc), "USDC");
        vm.label(address(universalRouter), "UniversalRouter");
        vm.label(address(uniswapRouter), "UniswapRouter");
        vm.label(user, "User");

        // Fondos iniciales
        mockUsdc.mint(address(this), 1_000_000e6);
        mockUsdc.approve(address(kipu), type(uint256).max);
        mockUsdc.approve(address(universalRouter), type(uint256).max);
    }

    function testInitialStats() public view {
        (uint256 deposits, uint256 withdrawals) = kipu.getStats();
        assertEq(deposits, 0);
        assertEq(withdrawals, 0);
    }

    function testVaultStartsEmpty() public view {
        uint256 balance = kipu.getVaultBalance(user);
        assertEq(balance, 0);
    }

    function testDepositUsdc() public {
        uint256 amount = 1000e6;

        mockUsdc.mint(user, amount);
        mockUsdc.mint(address(uniswapRouter), 1_000_000e6);

        vm.recordLogs();
        vm.prank(user);
        mockUsdc.approve(address(kipu), amount);

        vm.prank(user);
        kipu.deposit(address(mockUsdc), amount);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 1);

        bytes32 expectedTopic = keccak256("Deposit(address,address,uint256,uint256)");
        assertEq(logs[0].topics[0], expectedTopic);

        assertEq(address(uint160(uint256(logs[0].topics[1]))), user);
        assertEq(address(uint160(uint256(logs[0].topics[2]))), address(mockUsdc));

        (uint256 amountIn, uint256 usdcReceived) = abi.decode(logs[0].data, (uint256, uint256));
        assertEq(amountIn, amount);
        assertEq(usdcReceived, amount);

        assertEq(kipu.getVaultBalance(user), amount);
    }

    function testWithdrawUsdc() public {  
        uint256 amount = 1000e6;

        // Depositar primero
        mockUsdc.mint(user, amount);
        mockUsdc.mint(address(uniswapRouter), 1_000_000e6);

        vm.prank(user);
        mockUsdc.approve(address(kipu), amount);

        vm.prank(user);
        kipu.deposit(address(mockUsdc), amount);

        assertEq(mockUsdc.balanceOf(address(kipu)), 1000e6);

        // Retirar
        vm.prank(user);
        kipu.withdraw(amount);

        assertEq(kipu.getVaultBalance(user), 0);
    }

    function testDepositZeroReverts() public {
        vm.expectRevert(KipuBankV3.ZeroAmount.selector);
        kipu.deposit(usdc, 0);
    }

    function testWithdrawOverLimitReverts() public {
        uint256 amount = 20_000e6;
        mockUsdc.mint(user, amount);
        vm.prank(user);
        mockUsdc.approve(address(kipu), amount);
        vm.prank(user);
        kipu.deposit(address(mockUsdc), amount);

        vm.prank(user);
        vm.expectRevert(KipuBankV3.WithdrawalLimitExceeded.selector);
        kipu.withdraw(amount);
    }

    function testWithdrawInsufficientBalanceReverts() public {
        vm.prank(user);
        vm.expectRevert(KipuBankV3.InsufficientBalance.selector);
        kipu.withdraw(1000e6);
    }

    function testDepositWithSwapToken() public {
        // Simulamos un token que no es USDC
        uint256 amount = 500e18; // 500 tokens con 18 decimales
        
        MockERC20 tokenIn = new MockERC20();
        tokenIn.mint(user, amount);

        // Registramos sus decimales en el contrato
        kipu.setTokenDecimals(address(tokenIn), 18);
        mockUsdc.mint(address(uniswapRouter), 1_000_000e6);

        // Aprobamos y depositamos
        vm.prank(user);
        tokenIn.approve(address(kipu), amount);

        vm.recordLogs();
        vm.prank(user);
        kipu.deposit(address(tokenIn), amount);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 1);

        bytes32 expectedTopic = keccak256("Deposit(address,address,uint256,uint256)");
        assertEq(logs[0].topics[0], expectedTopic);

        assertEq(address(uint160(uint256(logs[0].topics[1]))), user);
        assertEq(address(uint160(uint256(logs[0].topics[2]))), address(tokenIn));

        (uint256 amountIn, uint256 usdcReceived) = abi.decode(logs[0].data, (uint256, uint256));
        assertEq(amountIn, amount);
        assertEq(usdcReceived, 1000e6);

        // El mock convierte 1 token = 2 USDC → esperamos 1000 USDC
        assertEq(kipu.getVaultBalance(user), 1000e6);
    }

    function testDepositEthSwap() public {
        uint256 ethAmount = 1 ether;

        // Asegurar que el router tenga USDC para entregar
        mockUsdc.mint(address(uniswapRouter), 1_000_000e6);

        vm.deal(user, ethAmount);
        vm.prank(user);
        kipu.deposit{value: ethAmount}(address(0), ethAmount);

        // El mock convierte 1 ETH = 1000 USDC
        assertEq(kipu.getVaultBalance(user), 1000e6);
    }

    function testDepositArbitraryToken() public {
        PermitTransferFrom memory permit = PermitTransferFrom({
            permitted: TokenPermissions({token: address(mockUsdc), amount: 1000e6}),
            nonce: 0,
            deadline: block.timestamp + 1 hours
        });

        SignatureTransferDetails memory transferDetails = SignatureTransferDetails({
            to: address(kipu),
            requestedAmount: 1000e6
        });

        bytes memory signature = hex"00"; // dummy firma
        bytes memory permitData = abi.encode(permit, transferDetails, signature);

        bytes memory dummyCommand = hex"01";
        bytes[] memory dummyInputs = new bytes[](1);
        dummyInputs[0] = hex"abcd";

        universalRouter.setSimulatedOutput(1000e6);
        mockUsdc.mint(address(universalRouter), 1000e6);
        console.log("Calling depositArbitraryToken...");

        kipu.depositArbitraryToken(
            address(mockUsdc),
            1000e6,
            permitData,
            dummyCommand,
            dummyInputs
        );
         console.log("Finished depositArbitraryToken");

        assertEq(kipu.getVaultBalance(address(this)), 1000e6);
    }
}