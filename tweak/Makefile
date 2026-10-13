include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AegisLock
AegisLock_FILES = Tweak.xm ../shared/ALPreferences.m
AegisLock_CFLAGS = -fobjc-arc -I../shared
AegisLock_FRAMEWORKS = UIKit Foundation Security
AegisLock_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk
