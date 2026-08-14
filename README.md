# Standalone CAEN NDT1470 IOC for FHF1 MUSIC1

This is a complete, independent EPICS IOC for the CAEN NDT1470 connected to
the FHF1 MUSIC1 field cage. It communicates directly with the module through
asyn and StreamDevice; the Python serial-to-EPICS bridge is not required. It
monitors voltage, current and status and can apply voltage and current-limit
setpoints to the module.

The IOC monitors the first three CAEN channels:

| CAEN channel | MUSIC field cage |
|---|---|
| CH0 | FC1 |
| CH1 | FC2 |
| CH2 | FC3 |

Each field cage provides:

- `HV_V_SET`: writable voltage setpoint (`VSET`), volts
- `HV_V_RBV`: measured voltage (`VMON`), volts
- `HV_I_SET`: writable current-limit setpoint (`ISET`), microamperes
- `HV_I_RBV`: measured current (`IMON`), microamperes
- `HV_STATE`: raw decimal CAEN status bitmask

`HV_V_SET` and `HV_I_SET` are StreamDevice `ao` records. At IOC startup they
read the existing values from the hardware, so startup does not overwrite the
module with zero. A successful write is followed by a hardware query that
updates the record with the value accepted by the module.

**Safety:** writing `HV_V_SET` while a channel is ON makes that channel ramp
toward the new voltage. This IOC intentionally does not provide channel ON/OFF
controls. Keep the hardware interlock, `MAXV`, current limit and approved
operating procedure in place.

## Requirements

- EPICS Base 7
- asyn built against that EPICS Base
- StreamDevice built against the same EPICS Base and asyn
- access to the CAEN serial device, normally through the Debian `dialout` group
- the NDT1470 in REMOTE control mode for `CMD:SET` operations

## 1. Configure the EPICS paths

The defaults in `configure/RELEASE` are:

```make
ASYN = $(HOME)/EPICS/support/asyn
STREAM = $(HOME)/EPICS/support/StreamDevice
EPICS_BASE = $(HOME)/EPICS/base-7.0.10
```

Edit that file if the modules are installed elsewhere. Alternatively, override
all three paths while building:

```bash
make \
  EPICS_BASE=/path/to/base-7.0.10 \
  ASYN=/path/to/asyn \
  STREAM=/path/to/StreamDevice
```

## 2. Build the standalone IOC

From the extracted project directory:

```bash
make -j"$(nproc)"
```

The resulting Debian x86-64 executable is:

```text
bin/linux-x86_64/musicNdt1470
```

## 3. Configure the serial device

Edit:

```text
iocBoot/iocmusicNdt1470/settings.cmd
```

Its initial settings are:

```iocsh
epicsEnvSet("MUSIC_PREFIX", "SFRS:FHF1:MUSIC1:")
epicsEnvSet("CAEN_PORT",    "MUSIC_HV")
epicsEnvSet("CAEN_DEVICE",  "/dev/ttyACM0")
epicsEnvSet("CAEN_BD",      "00")
epicsEnvSet("CAEN_BAUD",    "9600")
epicsEnvSet("HV_V_SET_MAX",  "3000")
epicsEnvSet("HV_I_SET_MAX",  "300")
```

`HV_V_SET_MAX` and `HV_I_SET_MAX` are the EPICS write limits applied to every
field cage. The supplied conservative defaults are 3000 V and 300 µA. Change
them only to the approved MUSIC1 limits. These software limits complement, but
do not replace, the module's hardware `MAXV` and interlocks.

For permanent operation, use the stable device link instead of
`/dev/ttyACM0`:

```bash
ls -l /dev/serial/by-id/
```

If the IOC account cannot open the serial port, add it to `dialout`, then log
out and back in:

```bash
sudo usermod -aG dialout "$USER"
```

Only one process can own the port. Stop `music_hv_2_epics.py` and any other
serial reader before starting this IOC. The MUSIC records must also remain
disabled in the common IOC to avoid duplicate PV names.

## 4. Run

From the project root:

```bash
./run.sh
```

The same IOC can be started directly with:

```bash
cd iocBoot/iocmusicNdt1470
../../bin/linux-x86_64/musicNdt1470 st.cmd
```

Stop it with `Ctrl+C` or the IOC-shell command `exit`.

## 5. Verify the PVs

In another terminal:

```bash
for fc in 1 2 3; do
  caget "SFRS:FHF1:MUSIC1:FC${fc}:HV_V_SET" \
        "SFRS:FHF1:MUSIC1:FC${fc}:HV_V_RBV" \
        "SFRS:FHF1:MUSIC1:FC${fc}:HV_I_SET" \
        "SFRS:FHF1:MUSIC1:FC${fc}:HV_I_RBV" \
        "SFRS:FHF1:MUSIC1:FC${fc}:HV_STATE"
done
```

## 6. Apply setpoints

After confirming the field-cage wiring, polarity, current limit, interlock and
channel mapping, write an approved value with:

```bash
caput SFRS:FHF1:MUSIC1:FC1:HV_V_SET VALUE_IN_VOLTS
caput SFRS:FHF1:MUSIC1:FC1:HV_I_SET VALUE_IN_MICROAMPERES
```

The IOC sends these commands and checks the CAEN acknowledgement:

```text
$BD:00,CMD:SET,CH:0,PAR:VSET,VAL:...
$BD:00,CMD:SET,CH:0,PAR:ISET,VAL:...
```

It then reads `VSET` or `ISET` back from the module. A timeout, malformed reply,
out-of-range response or LOCAL-mode rejection puts the EPICS record into an
alarm state. Check it after each write:

```bash
caget SFRS:FHF1:MUSIC1:FC1:HV_V_SET.STAT \
      SFRS:FHF1:MUSIC1:FC1:HV_V_SET.SEVR \
      SFRS:FHF1:MUSIC1:FC1:HV_I_SET.STAT \
      SFRS:FHF1:MUSIC1:FC1:HV_I_SET.SEVR
```

For serial diagnostics, add these lines in `st.cmd` immediately before
`iocInit` and remove them again after testing:

```iocsh
asynSetTraceIOMask("MUSIC_HV", -1, 0x2)
asynSetTraceMask("MUSIC_HV", -1, 0x9)
```

If the device does not answer, confirm the USB device path, board address `00`,
baud rate `9600`, and that no Python process still owns the port.

## Status bits

`HV_STATE` preserves the raw CAEN bitmask:

| Bit | Meaning |
|---:|---|
| 0 | Channel ON |
| 1 | Ramp up |
| 2 | Ramp down |
| 3 | Overcurrent |
| 4 | Overvoltage |
| 5 | Undervoltage |
| 6 | VMAX protection |
| 7 | Trip |
| 8 | Overpower |
| 9 | Overtemperature |
| 10 | Disabled |
| 11 | Kill |
| 12 | Interlock |
| 13 | Calibration error |
