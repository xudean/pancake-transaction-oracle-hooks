# pancake-offchaindata-hooks

## Overview

This repo creates a simple demo on a compliant DEX pool, using off-chain data attestations and the Hook feature in PancakeUniswap v4. We emphasise this repo is a prototype only, please don't use it in any product environment. 

Off-chain data attestations are privacy-preserving data proofs created by end users, through the [PADO](https://padolabs.org) protocol. PADO is a cryptographic attestation protocol to bring all Internet data into smart contracts.

The demo implements the following [proposal](https://hackmd.io/QXi9YUvUSwmqxCuGl7Z9XA), where users with submitted proofs-of-KYC-status can be privileged to swap tokens on DEX. This enables new scenarios like institutional swaps.

![image](https://hackmd.io/_uploads/BJDoNmdk6.png)


Besides the demo, PADO is an attestation protocol to support:
1. connecting with arbitrary data sources from TLS transmission, and proving the data authenticity;
2. general-purpose data computation with zkSNARKs;
3. high performance on any end-to-end process; 


## Prerequisite

Install foundry, see https://book.getfoundry.sh/getting-started/installation.

## Install

Get the repo:

```sh
git clone --recursive https://github.com/pado-labs/pancake-offchaindata-hooks.git
cd pancake-offchaindata-hooks
forge install
forge build
```

## Off-chain Transaction Hook

The [Off-chain Transaction Hook](./src/pool-cl/CLOffchainTransactionHook.sol) implements the `beforeAddLiquidity` and `beforeSwap` hooks.

![Off-chain Transaction Hook Contract](./docs/class/CLOffchainTransactionHook.svg)


## BSC-Testnet

### Configurations

1. Copy `./.env.bsc-testnet` to `./.env`, and set your private key (`PRIVATE_KEY`).
2. The following parameters are already set (see `./.env.bsc-testnet`):
   - Pancake Swap ([Vault](https://testnet.bscscan.com/address/0x08F012b8E2f3021db8bd2A896A7F422F4041F131), [CLPoolManager](https://testnet.bscscan.com/address/0x969D90aC74A1a5228b66440f8C8326a8dA47A5F9), [CLPositionManager](https://testnet.bscscan.com/address/0x89A7D45D007077485CB5aE2abFB740b1fe4FF574), [UniversalRouter](https://testnet.bscscan.com/address/0x30067B296Edf5BEbB1CB7b593898794DDF6ab7c5)). 
   - The arguments of Hook ([EAS](https://testnet.bscscan.com/address/0x6c2270298b1e6046898a322acB3Cbad6F99f7CBD), [EASProxy](https://testnet.bscscan.com/address/0x620e84546d71A775A82491e1e527292e94a7165A), [SchemaBytes](https://testnet.bascan.io/schema/0x5f868b117fd34565f3626396ba91ef0c9a607a0e406972655c5137c6d4291af9)).


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

- Deploy Hook

```sh
source .env
forge script script/DeployHook.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

output (sample):

```log
HOOK=0x74a47bc6916676443Db1d9dd14b25d451Bfb27A3
```

Add/replace the above address in `.env`.


### Testing


- Test Initialize

```sh
source .env
forge script script/Test.s.sol:TestInitializeScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

This command only needs to be executed once.

<br/>

- Test AddLiquidity

```sh
source .env
forge script script/Test.s.sol:TestAddLiquidityScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

<br/>

- Test Swap

```sh
source .env
forge script script/Test.s.sol:TestSwapScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```
