#import <UIKit/UIKit.h>
#import "ALPreferences.h"
#import <objc/message.h>
#import <notify.h>

static UIWindow *ALShieldWindow;
static BOOL ALHandlingBlock = NO;

static void ALHideShield(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        ALShieldWindow.hidden = YES;
        ALShieldWindow.rootViewController = nil;
        ALShieldWindow = nil;
        ALHandlingBlock = NO;
    });
}

static void ALSuspendApplication(void) {
    UIApplication *app = UIApplication.sharedApplication;
    SEL suspend = NSSelectorFromString(@"suspend");
    if ([app respondsToSelector:suspend]) {
        ((void(*)(id, SEL))objc_msgSend)(app, suspend);
    } else {
        exit(0);
    }
}

static void ALDismissAlertAndSuspend(void) {
    ALShieldWindow.hidden = YES;
    ALShieldWindow.rootViewController = nil;
    ALShieldWindow = nil;
    ALHandlingBlock = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.08 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{ ALSuspendApplication(); });
}

static void ALShowBlockedAlert(NSString *bundleID, NSString *appName) {
    if (ALHandlingBlock) return;
    ALHandlingBlock = YES;
    ALAppendAccessLog(bundleID, appName);

    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect frame = UIScreen.mainScreen.bounds;
        ALShieldWindow = [[UIWindow alloc] initWithFrame:frame];
        ALShieldWindow.windowLevel = UIWindowLevelAlert + 5000;
        ALShieldWindow.backgroundColor = UIColor.clearColor;

        UIViewController *vc = [UIViewController new];
        vc.view.backgroundColor = UIColor.clearColor;

        ALShieldWindow.rootViewController = vc;
        ALShieldWindow.hidden = NO;
        [ALShieldWindow makeKeyAndVisible];

        NSString *message = [NSString stringWithFormat:@"%@\n\n%@", ALBlockedMessage(), appName.length ? appName : bundleID];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"AegisLock"
                                                                        message:message
                                                                 preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                                 style:UIAlertActionStyleDefault
                                               handler:^(__unused UIAlertAction *action) {
            ALDismissAlertAndSuspend();
        }]];
        [vc presentViewController:alert animated:YES completion:nil];
    });
}

static void ALCheckCurrentApplication(void) {
    if (!ALRepairModeEnabled()) {
        ALHideShield();
        return;
    }
    NSString *bundleID = NSBundle.mainBundle.bundleIdentifier;
    NSString *appName = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (!appName.length) appName = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleName"];
    if (!ALIsBundleAllowed(bundleID)) ALShowBlockedAlert(bundleID, appName);
    else ALHideShield();
}

static void ALPrefsChanged(int token) {
    dispatch_async(dispatch_get_main_queue(), ^{ ALCheckCurrentApplication(); });
}

%ctor {
    @autoreleasepool {
        NSString *bundleID = NSBundle.mainBundle.bundleIdentifier;
        if ([bundleID isEqualToString:@"com.apple.springboard"]) return;

        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                          object:nil
                                                           queue:NSOperationQueue.mainQueue
                                                      usingBlock:^(__unused NSNotification *note) {
            ALCheckCurrentApplication();
        }];

        int token = 0;
        notify_register_dispatch(ALPrefsChangedNotification.UTF8String, &token,
                                 dispatch_get_main_queue(), ^(int t) { ALPrefsChanged(t); });

        int disableToken = 0;
        notify_register_dispatch(ALDisableRepairModeNotification.UTF8String, &disableToken,
                                 dispatch_get_main_queue(), ^(__unused int t) {
            ALSetRepairMode(NO);
            ALHideShield();
        });

        dispatch_async(dispatch_get_main_queue(), ^{ ALCheckCurrentApplication(); });
    }
}
