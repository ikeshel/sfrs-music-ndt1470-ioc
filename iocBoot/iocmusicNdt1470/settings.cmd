# FHF1 MUSIC1 installation settings

epicsEnvSet("MUSIC_PREFIX", "SFRS:FHF1:MUSIC1:")
epicsEnvSet("CAEN_PORT",    "MUSIC_HV")
epicsEnvSet("CAEN_DEVICE",  "/dev/ttyACM0")
epicsEnvSet("CAEN_BD",      "00")
epicsEnvSet("CAEN_BAUD",    "9600")

# EPICS CAS server port. This is the port that the IOC will listen on for incoming CA connections.
epicsEnvSet("EPICS_CAS_SERVER_PORT", "5066")


#########
# EPICS write limits. Set these to the approved MUSIC1 operating envelope.
epicsEnvSet("HV_V_SET_MAX",  "3000") # Voltage setpoint limit in volts
epicsEnvSet("HV_I_SET_MAX",  "300")  # Current setpoint limit in microamps

# EPICS default ramp rates. These are the default values that will be used when the IOC starts up.
epicsEnvSet("HV_RAMP_UP_DEFAULT",   "1") # Ramp-up speed in V/s
epicsEnvSet("HV_RAMP_DOWN_DEFAULT", "2") # Ramp-down speed in V/s