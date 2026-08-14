TOP = ../..

include $(TOP)/configure/CONFIG

PROD_IOC = musicNdt1470

DBD += musicNdt1470.dbd
musicNdt1470_DBD += base.dbd
musicNdt1470_DBD += asyn.dbd
musicNdt1470_DBD += drvAsynSerialPort.dbd
musicNdt1470_DBD += stream.dbd

musicNdt1470_SRCS += musicNdt1470_registerRecordDeviceDriver.cpp
musicNdt1470_SRCS_DEFAULT += musicNdt1470Main.cpp
musicNdt1470_SRCS_vxWorks += -nil-

musicNdt1470_LIBS += stream
musicNdt1470_LIBS += asyn
musicNdt1470_LIBS += $(EPICS_BASE_IOC_LIBS)

include $(TOP)/configure/RULES
