#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

FOUNDATION_EXPORT NSString * const ALPrefsDomain;
FOUNDATION_EXPORT NSString * const ALPrefsChangedNotification;
FOUNDATION_EXPORT NSString * const ALDisableRepairModeNotification;

BOOL ALRepairModeEnabled(void);
NSArray<NSString *> *ALAllowedBundleIDs(void);
void ALSetAllowedBundleIDs(NSArray<NSString *> *bundleIDs);
BOOL ALIsBundleAllowed(NSString * _Nullable bundleID);
BOOL ALHasPasscode(void);
BOOL ALVerifyPasscode(NSString *passcode);
BOOL ALSetPasscode(NSString *passcode);
void ALSetRepairMode(BOOL enabled);
NSString *ALBlockedMessage(void);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
