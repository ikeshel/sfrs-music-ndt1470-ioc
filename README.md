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

- `NHV:V_SET`: writable voltage setpoint (`VSET`), volts
- `NHV:V_RBV`: measured voltage (`VMON`), volts
- `NHV:I_SET`: writable current-limit setpoint (`ISET`), microamperes
- `NHV:I_RBV`: measured current (`IMON`), microamperes
- `NHV:STATUS`: raw decimal CAEN status bitmask

`NHV:V_SET` and `NHV:I_SET` are StreamDevice `ao` records. At IOC startup they
read the existing values from the hardware, so startup does not overwrite the
module with zero. A successful write is followed by a hardware query that
updates the record with the value accepted by the module.

**Safety:** writing `NHV:V_SET` while a channel is ON makes that channel ramp
toward the new voltage. The IOC provides `NHV:ENABLE` (0=OFF, 1=ON). Keep the hardware interlock, `MAXV`, current limit and approved
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
epicsEnvSet("HV_V_SET_MAX",  "4500")
epicsEnvSet("HV_I_SET_MAX",  "80")
epicsEnvSet("HV_RAMP_UP_DEFAULT",   "400")
epicsEnvSet("HV_RAMP_DOWN_DEFAULT", "500")
```

`HV_V_SET_MAX` and `HV_I_SET_MAX` are the EPICS write limits applied to every
field cage. The configured limits are 4500 V and 80 µA. Change
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
  caget "SFRS:FHF1:MUSIC1:FC${fc}:NHV:V_SET" \
        "SFRS:FHF1:MUSIC1:FC${fc}:NHV:V_RBV" \
        "SFRS:FHF1:MUSIC1:FC${fc}:NHV:I_SET" \
        "SFRS:FHF1:MUSIC1:FC${fc}:NHV:I_RBV" \
        "SFRS:FHF1:MUSIC1:FC${fc}:NHV:STATUS"
done
```

## 6. Apply setpoints

After confirming the field-cage wiring, polarity, current limit, interlock and
channel mapping, write an approved value with:

```bash
caput SFRS:FHF1:MUSIC1:FC1:NHV:V_SET VALUE_IN_VOLTS
caput SFRS:FHF1:MUSIC1:FC1:NHV:I_SET VALUE_IN_MICROAMPERES
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
caget SFRS:FHF1:MUSIC1:FC1:NHV:V_SET.STAT \
      SFRS:FHF1:MUSIC1:FC1:NHV:V_SET.SEVR \
      SFRS:FHF1:MUSIC1:FC1:NHV:I_SET.STAT \
      SFRS:FHF1:MUSIC1:FC1:NHV:I_SET.SEVR
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

`NHV:STATUS` preserves the raw CAEN bitmask:

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

## Polarity naming migration

Canonical PVs use `FC<n>:NHV:<parameter>`; every record also has a
`FC<n>:NEGATIVE:<parameter>` alias. Parameters are `V_SET`, `V_RBV`,
`I_SET`, `I_RBV`, `RAMP_UP_SET`, `RAMP_DOWN_SET`, `ENABLE` and `STATUS`.
For example, `SFRS:FHF1:MUSIC1:FC1:NEGATIVE:V_RBV` is the same record
as `SFRS:FHF1:MUSIC1:FC1:NHV:V_RBV`.

Update clients from `FC1:HV_V_RBV` to `FC1:NHV:V_RBV` and from
`FC1:HV_STATE` to `FC1:NHV:STATUS`. Old `HV_*` aliases are not provided,
so the positive and negative IOCs can share the MUSIC prefix without collisions.
Rebuild and restart both IOCs to load the new names. This naming change does
not alter hardware polarity or the protocol's voltage sign convention.

The deployed NDT1470 database and protocol are also kept in the build source
under `musicNdt1470App/Db` so rebuilding retains enable and ramp controls.

## Operating configuration (2026-11-16)

The operator confirmed that all hardware channels are set to negative polarity.
`NHV` and `NEGATIVE` names describe this configuration; the IOC does not switch
or verify hardware polarity. Voltage commands retain the positive-magnitude
convention, with an EPICS range of 0 to 4500 V. This software limit does not
program the module's hardware `MAXV`.

At every IOC startup, each configured channel receives ramp-up **400 V/s** and
ramp-down **500 V/s**, followed by a query of the accepted value. Ramp records
use `PINI=YES` and have no protocol `@init` read that could replace these defaults
with old hardware settings. Voltage and current setpoints retain their hardware
initialization reads, and output enable is not processed at boot.
The EPICS current-setpoint maximum is 80 µA. This does not automatically
change the hardware ISET value read at startup. FHF1 uses CH0–CH2 and FMF1 uses CH0–CH1;
unconfigured channels receive no commands.

After building and restarting the IOC, verify values and alarms (replace FHF1
with FMF1 and use field cages 1–2 for that installation):

```bash
for fc in 1 2 3; do
  for ramp in RAMP_UP_SET RAMP_DOWN_SET; do
    pv="SFRS:FHF1:MUSIC1:FC${fc}:NHV:${ramp}"
    caget "$pv" "$pv.STAT" "$pv.SEVR"
  done
  caget "SFRS:FHF1:MUSIC1:FC${fc}:NHV:V_SET.DRVH"
done
```

Expected ramp values are 400 and 500 with no alarms, and `DRVH` is 4500.
A displayed default alone does not prove that the hardware accepted the write:
check the alarms and module display. Existing USB disconnections or protocol
reply errors must be resolved before hardware application can be confirmed.

## NHV display ranges

Readbacks and setpoints use positive magnitudes: voltage 0–4500 V and
current 0–80 µA. Readback `LOPR` is zero, matching the setpoint range.
The current `HIGH` reference is 75 µA and `HIHI` is 80 µA; voltage references
remain 4250 V and 4500 V. EPICS threshold severities remain disabled; these
changes do not introduce new PV alarms or change hardware trip settings.

The shared Phoebus display lives in the sibling `sfrs-dcs-epics` repository,
under both `CSS_examples/Main Concept/MUSIC` and
`CSS_examples/New Concept/MUSIC`. Its NHV meter settings use display limits
from the PV and explicit visual bands: no low-current/low-voltage warning
band, upper voltage bands at 4250/4500 V, and upper current bands at 75/80 µA.
The 75 µA band is an early visual warning, not a hardware current limit.
Without those widget settings, disabled EPICS alarms supply no usable alarm
metadata and Phoebus falls back to generic 10/20/80/90 bands. The PHV display
configuration is unchanged.

The NHV display selects `MUSIC_NHV.plt`, with linear, fixed axes of 0–4500 V
and 0–80 µA. This prevents a constant setpoint from producing a very narrow
voltage axis and makes zero current visible (a logarithmic axis cannot show
zero). The plot contains both voltage setpoint and voltage readback; a nonzero
setpoint while the channel is OFF is not a measured output voltage.

Deploy both the IOC database and the shared Phoebus display changes. Build and
restart the IOC, then reopen the display to reload its widgets and PV metadata.
For example, verify the deployed IOC metadata without writing to hardware:

```bash
caget -d DBR_CTRL_DOUBLE SFRS:FHF1:MUSIC1:FC1:NHV:V_RBV
caget -d DBR_CTRL_DOUBLE SFRS:FHF1:MUSIC1:FC1:NHV:I_RBV
```

The display limits should be 0/4500 and 0/80 respectively. Alarm limits can
remain NaN because threshold alarm severities are disabled; the NHV gauge
uses its explicit visual bands instead.
