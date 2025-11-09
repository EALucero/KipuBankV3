// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { IUniswapV2Router02 } from "v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/**
 * @title KipuBankV3
 * @notice Bóveda DeFi con integración a Uniswap V2 y contabilidad en USDC (Sepolia)
 * @dev Acepta ETH, USDC y cualquier token con par directo a USDC en Uniswap V2
 * @author EALucero
 */
contract KipuBankV3 is AccessControl, ReentrancyGuard {
    // ─────── ROLES ─────── //
    /// @notice Rol administrativo con permisos para configurar tokens y parámetros
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // ─────── CONSTANTES ─────── //
    /// @notice Dirección que representa ETH como token nativo
    address public constant NATIVE_TOKEN = address(0);

    // ─────── VARIABLES IMMUTABLES ─────── //
    /// @notice Dirección del contrato USDC en Sepolia
    address public immutable USDC;
    /// @notice Dirección del contrato de Uniswap
    IUniswapV2Router02 public immutable UNISWAP_ROUTER;
    /// @notice Límite global de depósitos en el banco en USDC
    uint256 public immutable BANK_CAP_USD;
    /// @notice Umbral máximo de retiro por transacción en USDC
    uint256 public immutable WITHDRAWAL_LIMIT_USDC;

    // ─────── VARIABLES DE ESTADO ─────── //
    /// @notice Mapeo de bóvedas por usuario y token (vaults[user][token])
    mapping(address => mapping(address => uint256)) public vaults; // balance en USDC
    /// @notice Mapeo de decimales por token
    mapping(address => uint8) public tokenDecimals; // token => decimals
    /// @notice Total de depósitos realizados
    uint256 public totalDeposits;
    /// @notice Total de retiros realizados
    uint256 public totalWithdrawals;

    // ─────── EVENTOS ─────── //
    /// @notice Emitido cuando un usuario deposita fondos
    event Deposit(address indexed user, address indexed tokenIn, uint256 amountIn, uint256 usdcReceived);
    /// @notice Emitido cuando un usuario retira fondos
    event Withdrawal(address indexed user, uint256 amountUsdc);

    // ─────── ERRORES ─────── //
    /// @notice El token proporcionado no está registrado o no tiene decimales configurados
    error InvalidToken();
    /// @notice El depósito excede el límite global permitido por el banco
    error CapExceeded();
    /// @notice El usuario intenta retirar más fondos de los que tiene en su bóveda
    error InsufficientBalance();
    /// @notice Falló la transferencia de fondos (ETH o ERC-20)
    error TransferFailed();
    /// @notice El monto ingresado es cero, o sea nulo
    error ZeroAmount();
    /// @notice El retiro solicitado supera el límite máximo permitido por transacción
    error WithdrawalLimitExceeded();
    /// @notice Uniswap no devuelve los valores esperados
    error SwapFailed();

    // ─────── CONSTRUCTOR ─────── //
    /**
     * @notice Inicializa el contrato con límites y roless
     * @param _usdc Dirección del token USDC
     * @param _router Dirección del router de Uniswap V2
     * @param _bankCapUsd Límite total de depósitos en USDC
     * @param _withdrawalLimitUsdc Límite máximo de retiro por transacción en USDC
     */
    constructor(address _usdc, address _router, uint256 _bankCapUsd, uint256 _withdrawalLimitUsdc) {
        if (_usdc == address(0) || _router == address(0)) revert InvalidToken();
        if (_bankCapUsd == 0 || _withdrawalLimitUsdc == 0 || _withdrawalLimitUsdc > _bankCapUsd) revert CapExceeded();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        USDC = _usdc;
        UNISWAP_ROUTER = IUniswapV2Router02(_router);
        BANK_CAP_USD = _bankCapUsd;
        WITHDRAWAL_LIMIT_USDC = _withdrawalLimitUsdc;

        tokenDecimals[NATIVE_TOKEN] = 18;
        tokenDecimals[_usdc] = 6;
    }

    // ─────── FUNCIONES DE DEPÓSITO ─────── //
    /// @notice Permite depositar ETH directamente
    receive() external payable {
        if (msg.value == 0) revert ZeroAmount();
        _swapAndDeposit(msg.sender, NATIVE_TOKEN, msg.value);
    }

    /**
     * @notice Deposita tokens (ETH, USDC o cualquier ERC20 con par USDC)
     * @param tokenIn Token a depositar
     * @param amountIn Monto a depositar
     */
    function deposit(address tokenIn, uint256 amountIn) external payable nonReentrant {
        if (amountIn == 0) revert ZeroAmount();

        if (tokenIn == NATIVE_TOKEN) {
            require(msg.value == amountIn, "ETH mismatch");
        } else {
            bool ok = IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
            if (!ok) revert TransferFailed();
        }

        _swapAndDeposit(msg.sender, tokenIn, amountIn);
    }

    function _swapAndDeposit(address user, address tokenIn, uint256 amountIn) internal {
        uint256 usdcReceived;

        if (tokenIn == USDC) {
            usdcReceived = amountIn;
        } else {
            address[] memory path = new address[](2);
            path[0] = tokenIn == NATIVE_TOKEN ? UNISWAP_ROUTER.WETH() : tokenIn;
            path[1] = USDC;

            uint256[] memory amounts;
            if (tokenIn == NATIVE_TOKEN) {
                amounts = UNISWAP_ROUTER.swapExactETHForTokens{value: amountIn}(
                    0, path, address(this), block.timestamp
                );
            } else {
                IERC20(tokenIn).approve(address(UNISWAP_ROUTER), amountIn);
                amounts = UNISWAP_ROUTER.swapExactTokensForTokens(
                    amountIn, 0, path, address(this), block.timestamp
                );
            }

            if (amounts.length < 2) revert SwapFailed();
            usdcReceived = amounts[1];
        }

        if (totalDeposits + usdcReceived > BANK_CAP_USD) revert CapExceeded();

        vaults[user][USDC] += usdcReceived;
        totalDeposits += usdcReceived;

        emit Deposit(user, tokenIn, amountIn, usdcReceived);
    }

    // ─────── FUNCIONES DE RETIRO ─────── //
    /**
     * @notice Retira USDC desde la bóveda personal
     * @param amountUsdc Monto a retirar en USDC
     */
    function withdraw(uint256 amountUsdc) external nonReentrant {
        if (amountUsdc == 0) revert ZeroAmount();
        if (amountUsdc > WITHDRAWAL_LIMIT_USDC) revert WithdrawalLimitExceeded();
        if (vaults[msg.sender][USDC] < amountUsdc) revert InsufficientBalance();

        vaults[msg.sender][USDC] -= amountUsdc;
        totalDeposits -= amountUsdc;
        totalWithdrawals += amountUsdc;

        bool ok = IERC20(USDC).transfer(msg.sender, amountUsdc);
        if (!ok) revert TransferFailed();

        emit Withdrawal(msg.sender, amountUsdc);
    }

    // ─────── FUNCIONES DE CONSULTA ─────── //
    /**
     * @notice Consulta el balance de la bóveda de un usuario en USDC
     * @param user Dirección del usuario
     * @return balance Monto depositado en USDC
     */
    function getVaultBalance(address user) external view returns (uint256) {
        return vaults[user][USDC];
    }

    /**
     * @notice Retorna estadísticas globales del contrato
     * @return deposits Total de depósitos en USD
     * @return withdrawals Total de retiros en USD
     */
    function getStats() external view returns (uint256 deposits, uint256 withdrawals) {
        return (totalDeposits, totalWithdrawals);
    }

    /**
     * @notice Consulta el balance total en USDC de un usuario
     * @param user Dirección del usuario
     * @return totalUSD Monto total en USDC
     */
    function getTotalBalanceUsdc(address user) external view returns (uint256) {
        return vaults[user][USDC];
    }

    // ─────── FUNCIONES ADMINISTRATIVAS ─────── //
    /**
     * @notice Configura los decimales de un token
     * @param token Dirección del token
     * @param decimals Cantidad de decimales
     */
    function setTokenDecimals(address token, uint8 decimals) external onlyRole(ADMIN_ROLE) {
        tokenDecimals[token] = decimals;
    }
}