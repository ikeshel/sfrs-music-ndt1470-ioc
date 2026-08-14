TOP = .

include $(TOP)/configure/CONFIG

DIRS := configure
DIRS += musicNdt1470App
DIRS += iocBoot

include $(TOP)/configure/RULES_TOP
