#!/usr/bin/env bash

set -euo pipefail

ioc_root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ioc_arch=${EPICS_HOST_ARCH:-linux-x86_64}
ioc_binary="$ioc_root/bin/$ioc_arch/musicNdt1470"
ioc_boot="$ioc_root/iocBoot/iocmusicNdt1470"

export EPICS_CAS_SERVER_PORT="${EPICS_CAS_SERVER_PORT:-5066}"

# ---------------------------------------------------------------------------
# Select the PV location from the computer hostname
# ---------------------------------------------------------------------------

ioc_hostname=$(hostname -s)
ioc_hostname_lower=${ioc_hostname,,}

case "$ioc_hostname_lower" in
    x86l-261)
        pv_location="FHF1"
        ;;

    x86l-260)
        pv_location="FMF1"
        ;;

    # Add additional IOC computers here:
    #
    # dtlpc019)
    #     pv_location="FMF1"
    #     ;;

    *)
        echo "Unknown IOC computer: $ioc_hostname" >&2
        echo "Add this hostname to the mapping in $0" >&2
        exit 1
        ;;
esac

export IOC_HOSTNAME="$ioc_hostname"
export PV_LOCATION="$pv_location"

# ---------------------------------------------------------------------------
# Locate the CAEN USB device using its persistent device name
# ---------------------------------------------------------------------------

export CAEN_DEVICE="/dev/serial/by-id/usb-CAEN_SPA_NIM_Desktop_HV_Power_Supply-if00"

if [[ ! -e "$CAEN_DEVICE" ]]; then
    echo "CAEN NDT1470 device not found." >&2
    echo "Expected: $CAEN_DEVICE" >&2
    echo "Available serial devices:" >&2

    if [[ -d /dev/serial/by-id ]]; then
        ls -l /dev/serial/by-id >&2
    else
        echo "  /dev/serial/by-id does not exist" >&2
    fi

    exit 1
fi

if [[ ! -r "$CAEN_DEVICE" || ! -w "$CAEN_DEVICE" ]]; then
    echo "No read/write permission for CAEN device:" >&2
    echo "  $CAEN_DEVICE" >&2
    echo "Current user: $(id -un)" >&2
    echo "Groups: $(id -Gn)" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Validate the IOC installation
# ---------------------------------------------------------------------------

if [[ ! -x "$ioc_binary" ]]; then
    echo "IOC executable not found: $ioc_binary" >&2
    echo "Build it first by running: make" >&2
    exit 1
fi

if [[ ! -d "$ioc_boot" ]]; then
    echo "IOC boot directory not found: $ioc_boot" >&2
    echo "Create it first by running: make" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Print the selected configuration
# ---------------------------------------------------------------------------

echo "Starting MUSIC NDT1470 IOC"
echo "  Hostname:     $IOC_HOSTNAME"
echo "  PV location:  $PV_LOCATION"
echo "  PV prefix:    SFRS:${PV_LOCATION}:MUSIC1:"
echo "  CAEN device:  $CAEN_DEVICE"
echo "  CA server:    $EPICS_CAS_SERVER_PORT"
echo "  Architecture: $ioc_arch"

cd "$ioc_boot"
exec "$ioc_binary" st.cmd