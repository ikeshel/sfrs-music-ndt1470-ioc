# FHF1 MUSIC1 installation settings

epicsEnvSet("MUSIC_PREFIX", "SFRS:FHF1:MUSIC1:")
epicsEnvSet("CAEN_PORT",    "MUSIC_HV")
epicsEnvSet("CAEN_DEVICE",  "/dev/ttyACM0")
epicsEnvSet("CAEN_BD",      "00")
epicsEnvSet("CAEN_BAUD",    "9600")

# EPICS write limits. Set these to the approved MUSIC1 operating envelope.
epicsEnvSet("HV_V_SET_MAX",  "3000")
epicsEnvSet("HV_I_SET_MAX",  "300")

# EPICS CAS server port. This is the port that the IOC will listen on for incoming CA connections.
epicsEnvSet("EPICS_CAS_SERVER_PORT", "5066")
