#
# i.keshelashvili@gsi.de
#
# FMF1 or FHF1, MUSIC1 installation settings

epicsEnvSet("MUSIC_PREFIX", "SFRS:$(PV_LOCATION):MUSIC1:")
epicsEnvSet("CAEN_PORT",    "MUSIC_HV")
epicsEnvSet("CAEN_BD",      "00")
epicsEnvSet("CAEN_BAUD",    "9600")

# epicsEnvSet("CAEN_DEVICE",  "/dev/ttyACM0")
# epicsEnvSet("CAEN_DEVICE",  "/dev/serial/by-id/usb-CAEN_SPA_NIM_Desktop_HV_Power_Supply-if00")

#########
# All channels physically set to negative polarity (operator confirmed 2026-11-16).
# Voltage setpoints remain positive magnitudes, limited to 4500 V through EPICS.
# This does not program the hardware MAXV limit.
# EPICS write limits. Set these to the approved MUSIC1 operating envelope.
epicsEnvSet("HV_V_SET_MAX",  "4500") # Voltage setpoint limit in volts
epicsEnvSet("HV_I_SET_MAX",  "80")    # Current setpoint limit in microamps

# Ramp rates written to each configured channel at IOC startup (then read back).
epicsEnvSet("HV_RAMP_UP_DEFAULT",   "400") # Ramp-up speed in V/s
epicsEnvSet("HV_RAMP_DOWN_DEFAULT", "500") # Ramp-down speed in V/s
