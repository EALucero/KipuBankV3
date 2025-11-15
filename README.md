# 🏦 KipuBankV3

KipuBankV3 es una bóveda DeFi modular desplegada en Sepolia que permite a los usuarios depositar ETH, USDC o cualquier token ERC-20 con par directo a USDC en Uniswap V2. Ofrece contabilidad interna en USDC, swaps automáticos, límites configurables y trazabilidad total mediante eventos auditables.

## 📋 Características

- 💸 Depósitos en ETH, USDC o cualquier token ERC-20 con par directo a USDC
- 🔄 Swaps automáticos vía Uniswap V2 (router parametrizable)
- 🧮 Contabilidad interna en USDC (sin oráculos externos)
- 🏦 Límite global de depósitos (BANK_CAP_USDC)
- 🔐 Límite máximo por retiro (WITHDRAWAL_LIMIT_USDC)
- 🧾 Bóvedas personales por usuario (vaults[user][USDC])
- 🧩 Decimales configurables por token (setTokenDecimals)
- ⛔ Reversión automática si el monto es cero (ZeroAmount)
- 🛡️ Protección contra reentrancia (ReentrancyGuard)
- 📊 Estadísticas globales (getStats)
- 📣 Eventos trazables (Deposit, Withdrawal)
- 📊 Estadísticas globales (getStats)
- ⚙️ Despliegue reproducible vía .env y scripts de Foundry

## 🛠️ Despliegue

- Nota: Si no acepta la importación de variables del .env, usarlas directamente en los comandos

1. Clona el repositorio:
    - git clone https://github.com/EALucero/KipuBankV3.git
    - cd KipuBankV3
2. Crea tu archivo .env y configuralo según instrucciones de .env.example.    
3. Deploy con:
    forge script script/DeployKipuBankV3.s.sol:DeployKipuBankV3 \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast
4. Edita tu KIPU_ADDRESS, en .env, con la dirección del contrato KipuBankV3 deployado.
5. Interactua con el contrato con:
    forge script script/InteractKipuBankV3.s.sol:InteractKipuBankV3 \ 
    --rpc-url https://eth-sepolia.g.alchemy.com/v2/$ETHERSCAN_API_KEY \ 
    --private-key $PRIVATE_KEY \ 
    --broadcast
6. Se pueden modificar los valores predefinidos en .env al agregar por ej. 
   DEPOSIT_USDC=200000000 WITHDRAW_USDC=100000000 al principio del comando anterior.

## ☝🏼 Como interactuar

- 💰 Depositar ETH: Enviá ETH directamente al contrato (receive()).
- 💳 Depositar USDC u otro token ERC-20:
    1. approve(kipu, amount)
    2. deposit(token, amount)
- 💸 Retirar USDC: withdraw(amountUsdc).
- 📦 Consultar bóveda:: getVaultBalance(user).
- 📊 Consultar estadísticas: getStats().

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

https://sepolia.etherscan.io/address/0xbb4182b4e0547af38660392ad3eafd1b43fd61b1