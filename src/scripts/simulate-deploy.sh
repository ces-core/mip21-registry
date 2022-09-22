#!/bin/bash
set -eo pipefail

set +e
[ -f "${BASH_SOURCE%/*}/../../.env" ] && source "${BASH_SOURCE%/*}/../../.env"
FORGE_SCRIPT="${BASH_SOURCE%/*}/../../scripts/forge-script.sh"
set -e

simulate-deploy() {
  if ! grep -- '--fork-url' <<<"$@" >/dev/null; then
    echo "Missing --fork-url argument" >&2
    echo -e "\n$(usage)\n" >&2
    exit 1
  fi

  local ANVIL_PORT=8546
  local FORK_RPC_URL="http://localhost:${ANVIL_PORT}"

  # Start anvil
  anvil --port 8546 $@ &
  local ANVIL_PID=$!
  sleep 3

  local RESPONSE=$($FORGE_SCRIPT DeployRwaRegistry -vvv --broadcast --rpc-url $FORK_RPC_URL | tee >(cat 1>&2))
  local MIP21_REGISTRY=$(jq -Rr 'fromjson? | .returns["0"].value' <<<"$RESPONSE")

  # Impersonate MCD_PAUSE_PROXY to be able to modify the changelog
  local MCD_PAUSE_PROXY=$(cast call $CHANGELOG 'getAddress(bytes32)(address)' $(cast --from-ascii 'MCD_PAUSE_PROXY'))
  # We will need some balance to be able to send txs
  cast rpc anvil_setBalance $MCD_PAUSE_PROXY $(cast --to-wei 10 ETH)
  # Impersionate must be called right before the actual transaction
  cast rpc anvil_impersonateAccount $MCD_PAUSE_PROXY
  cast send $CHANGELOG 'setAddress(bytes32,address)' $(cast --from-ascii 'MIP21_REGISTRY') $MIP21_REGISTRY --from $MCD_PAUSE_PROXY

  cat <<MSG


RwaRegistry instance deployed and added to the CHANGELOG:

##############################################################
#                                                            #
# MIP21_REGISTRY: ${MIP21_REGISTRY} #
#                                                            #
##############################################################

MSG

  wait $ANVIL_PID
}

usage() {
  cat <<MSG
simulate-deploy.sh --fork-url <MAINNET_RPC_ENDPOINT>
MSG
}

if [ "$0" = "$BASH_SOURCE" ]; then
  [ "$1" = "-h" -o "$1" = "--help" ] && {
    echo -e "\n$(usage)\n"
    exit 0
  }

  simulate-deploy "$@"
fi
