#!/usr/bin/env bash

set -euo pipefail

ioc_root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ioc_arch=${EPICS_HOST_ARCH:-linux-x86_64}
ioc_binary="$ioc_root/bin/$ioc_arch/musicNdt1470"
ioc_boot="$ioc_root/iocBoot/iocmusicNdt1470"

## ss -lntup | grep -E ':(5064|5066)\b'
# export EPICS_CAS_SERVER_PORT=5066
export EPICS_CAS_SERVER_PORT="${EPICS_CAS_SERVER_PORT:-5066}"


# Check if the IOC binary exists and is executable
if [[ ! -x "$ioc_binary" ]]; then
    echo "IOC executable not found: $ioc_binary" >&2
    echo "Build it first by running: make" >&2
    exit 1
fi

# Check if the IOC boot directory exists
if [[ ! -d "$ioc_boot" ]]; then
    echo "IOC boot directory not found: $ioc_boot" >&2
    echo "Create it first by running: make" >&2
    exit 1
fi
cd "$ioc_boot"

# Start the IOC
exec "$ioc_binary" st.cmd
