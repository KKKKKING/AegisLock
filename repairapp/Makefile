include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = AegisRepair
AegisRepair_FILES = main.m AppDelegate.m RootViewController.m TouchTestViewController.m ScreenTestViewController.m ../shared/ALPreferences.m
AegisRepair_FRAMEWORKS = UIKit Foundation LocalAuthentication AVFoundation AudioToolbox Security
AegisRepair_RESOURCE_FILES = Info.plist
AegisRepair_CFLAGS = -fobjc-arc -I../shared
AegisRepair_INSTALL_PATH = /Applications

include $(THEOS_MAKE_PATH)/application.mk
