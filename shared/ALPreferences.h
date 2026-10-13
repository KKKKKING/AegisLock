#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const ALPrefsDomain;
FOUNDATION_EXPORT NSString * const ALPrefsChangedNotification;

BOOL ALRepairModeEnabled(void);
NSArray<NSString *> *ALAllowedBundleIDs(void);
BOOL ALIsBundleAllowed(NSString * _Nullable bundleID);
BOOL ALHasPasscode(void);
BOOL ALVerifyPasscode(NSString *passcode);
BOOL ALSetPasscode(NSString *passcode);
void ALSetRepairMode(BOOL enabled);
NSString *ALBlockedMessage(void);

NS_ASSUME_NONNULL_END
