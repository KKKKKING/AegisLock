include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = AegisLockPrefs
AegisLockPrefs_FILES = RootListController.m ../shared/ALPreferences.m
AegisLockPrefs_FRAMEWORKS = UIKit Foundation Security
AegisLockPrefs_PRIVATE_FRAMEWORKS = Preferences
AegisLockPrefs_INSTALL_PATH = /Library/PreferenceBundles
AegisLockPrefs_CFLAGS = -fobjc-arc -I../shared

include $(THEOS_MAKE_PATH)/bundle.mk
