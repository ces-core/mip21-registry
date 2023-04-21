# MIP-21 RWA Registry

On-chain registry for MIP-21 contracts for Real World Assets (RWA).

## Design

The RWA Registry aims to be flexible and extensible registry for all current and future [components of the
MIP-21](https://github.com/makerdao/mip21-toolkit) architecture, without requiring features such as upgradeability
and facets, which bring more complexity.

To prevent malicious updates, all non-view methods are permissioned.

### Deals

RWA deals are identified by their collateral type (`ilk`). RWA `ilk`s come in the form of `RWA123-A`, where `123` is a
sequential number.

Each RWA deal consists of:

- `status`: the status of the deal. Non-existent deals have a `NONE` status. It is set to `ACTIVE` once the deal is
  added to the registry and to `FINALIZED` once the deal is finished.
  ```
  ┌──────┐     add()    ┌────────┐  finalize()  ┌───────────┐
  │ NONE ├──────────────► ACTIVE ├──────────────► FINALIZED │
  └──────┘              └────────┘              └───────────┘
  ```
- `components`: the list of components of a deal.

### Supported Components

The contract maintains an append-only list of supported components, identified by their `camelCased` names.

- `addSupportedComponent(bytes32 componentName_): void`: adds a new supported component to the registry.
- `listSupportedComponents(): bytes32[]`: returns the list of supported components.

### Components

Deal components consist of:

- `name: bytes32`: the `camelCased` name of the component. It has to be one of the supported components.
- `addr: address`: the address of the component, be it a smart contract or an EOA.
- `variant: uint8`<sup>\*</sup>: we have identified early on that components fulfilling the same role may have different
  implementations. Following the same approach of the [`GemJoin` adapters](https://github.com/makerdao/dss-gem-joins/),
  each implementation has a numeric suffix identifying it. This allows consumers to know precisely with which
  implementation they are dealing with when querying the registry. Different components can have different reserved
  values for variants with special meaning and should be documented below.

<sup>\*</sup> Variant is only stored as `uint8`, but when used as `calldata` (parameters of or returning from functions)
they are upcast to `uint256`. See this
[article](https://blog.pessimistic.io/short-types-in-solidity-rare-tricks-uncovered-46b742c554c9) for further reference.

## List of currently supported components

### 1. `urn`

The RWA vault.

**Variants:**

|  #  | Description                                                                                                                    |
| :-: | :----------------------------------------------------------------------------------------------------------------------------- |
| `1` | The base implementation of a permissioned vault. See [`RwaUrn.sol`][rwa-urn].                                                  |
| `2` | A permissioned vault based on `#1`, allowing to claim deposited Dai without Emergency Shutdown. See [`RwaUrn2.sol`][rwa-urn2]. |

[rwa-urn]: https://github.com/makerdao/mip21-toolkit/blob/master/src/urns/RwaUrn.sol
[rwa-urn2]: https://github.com/makerdao/mip21-toolkit/blob/master/src/urns/RwaUrn2.sol

### 2. `liquidationOracle`

The RWA liquidation oracle, controlled by MakerDAO governance to put RWA vaults in liquidation when the conditions on
the deal are not met.

**Variants:**

|  #  | Description                                                                                                 |
| :-: | :---------------------------------------------------------------------------------------------------------- |
| `1` | The base implementation the of liquidation oracle. See [`RwaLiquidationOracle.sol`][rwa-liquidation-oracle] |

[rwa-liquidation-oracle]: https://github.com/makerdao/mip21-toolkit/blob/master/src/oracles/RwaLiquidationOracle.sol

### 3. `outputConduit`

The RWA output conduit, acts as a temporary holder for Dai when it is generated from a vault.

**Variants:**

|         #         | Description                                                                                                                                     |
| :---------------: | :---------------------------------------------------------------------------------------------------------------------------------------------- |
|        `1`        | The base implementation the output conduit. See [`RwaOutputConduit.sol`][rwa-output-conduit]                                                    |
|        `2`        | Based on `#1`, with a permissioned `push()` method. See [`RwaOutputConduit2.sol`][rwa-output-conduit2]                                          |
|        `3`        | Designed to swap Dai into PSM gems on `push()`. See [`RwaSwapOutputConduit.sol`][rwa-swap-output-conduit]                                       |
| `type(uint8).max` | Not a real conduit. Should be used when Dai is drawn directly into the destination and be treated as an opaque `address`, not a smart contract. |

[rwa-output-conduit]: https://github.com/makerdao/mip21-toolkit/blob/master/src/conduits/RwaOutputConduit.sol
[rwa-output-conduit2]: https://github.com/makerdao/mip21-toolkit/blob/master/src/conduits/RwaOutputConduit2.sol
[rwa-swap-output-conduit]: https://github.com/makerdao/mip21-toolkit/blob/master/src/conduits/RwaSwapOutputConduit.sol

### 4. `inputConduit`

The RWA input conduit, acts as a temporary holder for Dai or other gems when it is deposited into a vault.

**Variants:**

|          #          | Description                                                                                                                                                   |
| :-----------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------ |
|         `1`         | The base implementation the input conduit. See [`RwaInputConduit.sol`][rwa-input-conduit]                                                                     |
|         `2`         | Based on `#1`, with a permissioned `push()` method. See [`RwaInputConduit2.sol`][rwa-input-conduit2]                                                          |
|         `3`         | Designed to receive PSM gems and swap them into a Dai on `push()`. See [`RwaSwapInputConduit.sol`][rwa-swap-input-conduit]                                    |
|         `4`         | Designed to receive PSM gems and swap them into a Dai on `push()`, with a permissionless `push()`. See [`RwaSwapInputConduit2.sol`][rwa-swap-input-conduit-2] |
| `type(uint8).max-1` | Tinlake contract integration with Centrifuge protocol                                                                                                         |

[rwa-input-conduit]: https://github.com/makerdao/mip21-toolkit/blob/master/src/conduits/RwaInputConduit.sol
[rwa-input-conduit2]: https://github.com/makerdao/mip21-toolkit/blob/master/src/conduits/RwaInputConduit2.sol
[rwa-swap-input-conduit]: https://github.com/makerdao/mip21-toolkit/blob/master/src/conduits/RwaSwapInputConduit.sol
[rwa-swap-input-conduit-2]: https://github.com/makerdao/mip21-toolkit/blob/master/src/conduits/RwaSwapInputConduit2.sol

### 5. `jar`

The RWA container for stability fee payments directly into MakerDAO's Surplus Buffer.

**Variants:**

|  #  | Description                                                  |
| :-: | :----------------------------------------------------------- |
| `1` | The base implementation the jar. See [`RwaJar.sol`][rwa-jar] |

[rwa-jar]: https://github.com/makerdao/mip21-toolkit/blob/master/src/jars/RwaJar.sol

### 6. `jarInputConduit`

The RWA Jar input conduit, acts as a temporary holder for Dai or other gems when it is deposited into the jar for stability fee payments.

The main use case for `jarInputConduit` is when stability fees need to be paid using a PSM gem instead of Dai. The swap input conduit can be used for to swap the gem into Dai before moving it to the jar.

|  #  | Description                                                                                                                                                   |
| :-: | :------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `3` | Designed to receive PSM gems and swap them into a Dai on `push()`. See [`RwaSwapInputConduit.sol`][rwa-swap-input-conduit]                                    |
| `4` | Designed to receive PSM gems and swap them into a Dai on `push()`, with a permissionless `push()`. See [`RwaSwapInputConduit2.sol`][rwa-swap-input-conduit-2] |

## Guides

### Add a deal

```solidity
// Add a deal without any components
registy.add('<ILK>');

// Add a deal with components
registy.add(
    '<ILK>',
    ['liquidationOracle', 'urn', 'inputConduit', 'outputConduit'], // names
    [0x1234..., 0x1235..., 0x1236...,  0x1236...], // addresses
    [1, 1, 2, 2] // variants
);
```

### Update a component of a deal

```solidity
registy.setCompoonent('<ILK>', 'liquidationOracle', 0x1234..., 1);
```

### Get all components of a deal

```solidity
registy.listComponentsOf('<ILK>');
// Returns:
//   ['liquidationOracle', 'urn', 'inputConduit', 'outputConduit'], // names
//   [0x1234..., 0x1235..., 0x1236...,  0x1236...], // addresses
//   [1, 1, 2, 2] // variants
```

### Get a specific component of a deal by name

```solidity
registy.getCompoonent('<ILK>', 'liquidationOracle');
// Returns:
//   0x1234..., // address
//   1 // variant
```

### Add a new supported component

```solidity
registry.addSupportedComponent('newComponentName');
```

### Get all supported component names

```solidity
registry.listSupportedComponents();
// Returns:
//   ['liquidationOracle', 'urn', 'inputConduit', 'outputConduit', 'jar', 'jarInputConduit', ...]
```

## Contributing

### Install dependencies

```bash
# Install tools from the nodejs ecosystem: prettier, solhint, husky and lint-staged
make nodejs-deps
# Install smart contract dependencies through `foundry update`
make update
```

### Create a local `.env` file and change the placeholder values

```bash
cp .env.example .env
```

### Build contracts

```bash
make build
```

### Test contracts

```bash
make test # using a local node listening on http://localhost:8545
# Or
ETH_RPC_URL='https://eth-goerli.alchemyapi.io/v2/<ALCHEMY_API_KEY>' make test # using a remote node
```

### Helper scripts

Wrapper around `forge`/`cast` which figure out wallet and password automatically if you are using [`geth` keystore](https://geth.ethereum.org/docs/interface/managing-your-accounts).

- `scripts/forge-deploy.sh`: Deploys a contract. Accepts the same options as [`forge create`](https://book.getfoundry.sh/reference/forge/forge-create.html)
- `scripts/forge-verify.sh`: Verifies a deployed contract. Accepts the same options as [`forge verify-contract`](https://book.getfoundry.sh/reference/forge/forge-verify-contract.html)
- `scripts/cast-send.sh`: Signs and publish a transaction. Accepts the same options as [`cast send`](https://book.getfoundry.sh/reference/cast/cast-send.html)
