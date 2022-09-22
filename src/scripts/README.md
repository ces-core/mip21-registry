# Deploy MIP21 RWA Registry to a fork

This helper script is meant to be used as a temporary fixture while the MIP21 RWA Registry is not deployed and onboarded
into MCD.

## Usage

Run:

```bash
simulate-deploy.sh --fork-url <RPC_ENDPOINT>
```

The script above will:

1. Start an `anvil` node as a fork of the chain at `<RPC_ENDPOINT>`
2. Deploy the `RwaRegistry` contract and add `RWA008-A` and `RWA009-A` components to it.
3. Add the `MIP21_REGISTRY` key to the `CHANGELOG` with the address of the deployed `RwaRegistry`.
4. Keep the process running until it is interrupted (i.e.: <kbd>ctrl</kbd>+<kbd>c</kbd>).

By default, `anvil` will listen to port `8546`, but that can be configured with an `ANVIL_PORT` env var:

```bash
ANVIL_PORT=8889 simulate-deploy.sh --fork-url <RPC_ENDPOINT>
```

Then you can make calls and send transactions to `http://localshot:${ANVIL_PORT}`.
