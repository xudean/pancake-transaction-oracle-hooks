# pancake-transaction-oracle-hooks

## Overview

This repo creates a simple demo for DEX exclusive-access pools and better filters qualified users by combining off-chain and on-chain transaction data verification. This combination provides a more accurate representation of user transaction activities in a privacy-preserving way, giving applications more flexible filtering criteria. In the PancakeSwap case, a suitable exclusive-access condition could be if a user has a 30-day spot transaction volume exceeding $100000 on a CEX platform and has made an on-chain transaction on the BNB Chain, making this user a target user for DEX.

In this demo, transaction proofs can be submitted from the Primus extension or utilized by Primus's zkTLS SDK to attest the user's on-chain and off-chain transactions. Throughout the entire process, the user’s privacy is fully protected. Whether the user meets the exclusive-access demands could be verified by this hook contract. 

For off-chain transaction proof, [Primus's](https://primuslabs.xyz/) zkTLS and IZK techniques are used to verify whether the user’s 30-day spot transaction volume on CEX platforms, such as Binance or OKX, exceeds $100000 or a specific amount, depending on the application’s requirements.


![image](./docs/pics/process.jpeg)


## Prerequisite

Install foundry, see https://book.getfoundry.sh/getting-started/installation.

## Install

Get the repo:

```sh
git clone --recursive https://github.com/primus-labs/pancake-transaction-oracle-hooks.git
cd pancake-transaction-oracle-hooks
forge install
forge build
```

## Primus AttestionRegistry

The [AttestationRegistry](src/attestation/AttestationRegistry.sol) contract is used to register the attestation contract.

[AttestationRegistry Contract](./docs/src/src/attestation/AttestationRegistry.sol/contract.AttestationRegistry.md)



## CLExchangeVolumeHook

The [CLExchangeVolumeHook](src/pool-cl/volume/CLExchangeVolumeHook.sol) implements the `afterInitialize` and `beforeSwap` hooks.

[CLExchangeVolumeHook Contract](./docs/src/src/pool-cl/volume/CLExchangeVolumeHook.sol/contract.CLExchangeVolumeHook.md)

## BinExchangeVolumeHook

The [BinExchangeVolumeHook](src/pool-bin/volume/BinExchangeVolumeHook.sol) implements the `afterInitialize` and `beforeSwap` hooks.

[BinExchangeVolumeHook Contract](./docs/src/src/pool-bin/volume/BinExchangeVolumeHook.sol/contract.BinExchangeVolumeHook.md)

## BSC-Testnet

### Configurations

1. Copy `./.env.bsc-testnet` to `./.env`, and set your private key (`PRIVATE_KEY`).
2. The following parameters are already set:
   - Pancake Swap ([Vault](https://testnet.bscscan.com/address/0xd557753bde3f0EaF32626F8681Ac6d8c1EBA2BBa), [CLPoolManager](https://testnet.bscscan.com/address/0x70890E308DCE727180ac1B9550928fED342dea52), [CLPositionManager](https://testnet.bscscan.com/address/0x7E7856fBE18cd868dc9E2C161a7a78c53074D106), [UniversalRouter](https://testnet.bscscan.com/address/0x1c3112A0A62563F02D44659E6340409E02B6c02f)).
   - The arguments of Hook ([AttestationRegistry](https://testnet.bscscan.com/address/0x9109Ea5A8Af5c3c5600F6E8213bd83348C81a573)).


### Deployment


- Deploy Token


```sh
source .env
forge script script/DeployToken.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

output (sample):

```log
TOKEN0=0x772F5b156EDaa4874F3f4F81c5e4479EE7E1669B
TOKEN1=0x7AA33Aa23aB75D37A9c27B0ba51bb10ed6e41a51
```

Add/replace the above address in `.env`.

<br/>

- Deploy AttestationRegistry

```sh
source .env
forge script script/attestation/AttestationRegistry.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

output (sample):

```log
ATTESTATION_REGISTRY=0x6c2270298b1e6046898a322acB3Cbad6F99f7CBD
```

<br/>

- Deploy Hook

```sh
source .env
forge script script/pool-cl/DeployHook.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

output (sample):

```log
HOOK=0xd9Dd1FEaF845Dd036245A504317cCccE7Bc18f49
```

Add/replace the above address in `.env`.


### Before Testing

- Initialize Pool

```sh
source .env
forge script script/pool-cl/Test.s.sol:TestInitializeScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

This command only needs to be executed once.

<br/>

- Transfer Token (Optional)

Request some tokens from the Token owner. (If necessary)

```sh
source .env
export RECEIVER=<the receiver address>
# export RECEIVER=0x...
forge script script/Transfer.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

<br/>

- Token Approve

Before swap testing, need approve first.

```sh
source .env
forge script script/Approve.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

### Testing

- Test AddLiquidity

```sh
source .env
forge script script/pool-cl/Test.s.sol:TestAddLiquidityScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

<br/>

- Test Swap

```sh
source .env
forge script script/pool-cl/Test.s.sol:TestSwapScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```
