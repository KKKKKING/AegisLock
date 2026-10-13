include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = AegisLockPrefs
AegisLockPrefs_FILES = RootListController.m ALAppSelectionController.m ../shared/ALPreferences.m
AegisLockPrefs_FRAMEWORKS = UIKit Foundation Security
AegisLockPrefs_RESOURCE_FILES = Info.plist
AegisLockPrefs_INSTALL_PATH = /Library/PreferenceBundles
AegisLockPrefs_CFLAGS = -fobjc-arc -I../shared
AegisLockPrefs_LDFLAGS = -undefined dynamic_lookup

include $(THEOS_MAKE_PATH)/bundle.mk
