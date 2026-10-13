ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0
FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

SUBPROJECTS += tweak prefs repairapp

include $(THEOS_MAKE_PATH)/aggregate.mk
