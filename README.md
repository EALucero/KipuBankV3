# KipuBankV3

KipuBankV3 es una bóveda DeFi modular que permite a los usuarios depositar ETH, USDC o cualquier token ERC-20 con par directo a USDC en Uniswap V2. Ofrece contabilidad en USDC, límites configurables, swaps integrados y trazabilidad total mediante eventos auditables.

## 📋 Características

- 💸 Depósitos en ETH, USDC o cualquier token ERC-20 con par directo a USDC
- 🔄️ Integración directa con Uniswap V2 para swaps automáticos
- 🧮 Contabilidad interna en USDC (sin oráculos externos)
- 🏦 Límite global de depósitos (BANK_CAP_USD)
- 🔐 Límite máximo por retiro (WITHDRAWAL_LIMIT_USDC)
- 🧾 Bóvedas personales por usuario (vaults[user][USDC])
- 🧩 Decimales configurables por token (setTokenDecimals)
- ⛔ Reversión automática si el monto es cero (ZeroAmount)
- 🛡️ Protección contra reentrancia (ReentrancyGuard)
- 📊 Estadísticas globales (getStats)
- 📣 Eventos trazables en depósitos y retiros (Deposit, Withdrawal)
- 🧪 Suite de tests con validación de eventos vía recordLogs()

## 🛠️ Despliegue

1. Clona el repositorio:
    - git clone https://github.com/EALucero/KipuBankV3.git
    - cd KipuBankV3
2. Deployar en Remix o Foundry usando la red Sepolia.
3. Al momento del despliegue, configurar:
    - bankCapUsdc: límite global de depósitos en USDC (ej. 1_000_000e6)
    - withdrawalLimitUsdc: límite máximo por retiro (ej. 10_000e6)
    - USDC: dirección del contrato USDC en Sepolia
    - router: dirección del router Uniswap V2 (Sepolia)

## ☝🏼 Como interactuar

- Para depositar ETH: enviá ETH directamente al contrato (receive()).
- Para depositar USDC u otro token ERC-20:
    1. Aprobá el monto desde el token (approve(kipu, amount)).
    2. Ejecutá deposit(token, amount).
- Para retirar USDC: withdraw(amountUsdc).
- Consultá tu bóveda: getVaultBalance(user).
- Consultá estadísticas globales: getStats().

## 🔍 Variables clave

| Variables              | Descripción                            |
| ---------------------- |:--------------------------------------:|
| vaults[user][USDC]:    | Monto depositado por usuario en USDC   |
| totalDeposits:         | Total acumulado de depósitos en USDC   |
| totalWithdrawals:      | Total acumulado de retiros en USDC     |
| BANK_CAP_USDC:         | Límite global de depósitos             |
| WITHDRAWAL_LIMIT_USDC: | Límite máximo por retiro               |
| tokenDecimals[token]:  | Decimales configurados por token       |
| USDC:                  | Dirección del contrato USDC en Sepolia |
| UNISWAP_ROUTER:        | Dirección del router Uniswap V2        |
| NATIVE_TOKEN:          | Representación de ETH (address(0))     |              

## ✅ Verificación de contrato
https://sepolia.etherscan.io/address/0x9f9f1678dF0c37c6387A68aC7BDb7F4Ff7F7F5B7