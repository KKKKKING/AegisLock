#import <UIKit/UIKit.h>
#import "ALPreferences.h"
#import <objc/message.h>
#import <notify.h>

static UIWindow *ALShieldWindow;
static BOOL ALHandlingBlock = NO;

static void ALShowShieldAndSuspend(void) {
    if (ALHandlingBlock) return;
    ALHandlingBlock = YES;

    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect frame = UIScreen.mainScreen.bounds;
        ALShieldWindow = [[UIWindow alloc] initWithFrame:frame];
        ALShieldWindow.windowLevel = UIWindowLevelAlert + 5000;
        ALShieldWindow.backgroundColor = UIColor.systemBackgroundColor;

        UIViewController *vc = [UIViewController new];
        vc.view.backgroundColor = UIColor.systemBackgroundColor;

        UILabel *icon = [[UILabel alloc] initWithFrame:CGRectZero];
        icon.translatesAutoresizingMaskIntoConstraints = NO;
        icon.text = @"🔒";
        icon.font = [UIFont systemFontOfSize:54];
        icon.textAlignment = NSTextAlignmentCenter;

        UILabel *title = [[UILabel alloc] initWithFrame:CGRectZero];
        title.translatesAutoresizingMaskIntoConstraints = NO;
        title.text = ALBlockedMessage();
        title.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
        title.textAlignment = NSTextAlignmentCenter;
        title.numberOfLines = 0;

        UILabel *detail = [[UILabel alloc] initWithFrame:CGRectZero];
        detail.translatesAutoresizingMaskIntoConstraints = NO;
        detail.text = @"请使用 AegisRepair 进行硬件测试。";
        detail.font = [UIFont systemFontOfSize:14];
        detail.textColor = UIColor.secondaryLabelColor;
        detail.textAlignment = NSTextAlignmentCenter;
        detail.numberOfLines = 0;

        [vc.view addSubview:icon];
        [vc.view addSubview:title];
        [vc.view addSubview:detail];
        [NSLayoutConstraint activateConstraints:@[
            [icon.centerXAnchor constraintEqualToAnchor:vc.view.centerXAnchor],
            [icon.centerYAnchor constraintEqualToAnchor:vc.view.centerYAnchor constant:-55],
            [title.topAnchor constraintEqualToAnchor:icon.bottomAnchor constant:18],
            [title.leadingAnchor constraintEqualToAnchor:vc.view.leadingAnchor constant:28],
            [title.trailingAnchor constraintEqualToAnchor:vc.view.trailingAnchor constant:-28],
            [detail.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:10],
            [detail.leadingAnchor constraintEqualToAnchor:vc.view.leadingAnchor constant:28],
            [detail.trailingAnchor constraintEqualToAnchor:vc.view.trailingAnchor constant:-28]
        ]];

        ALShieldWindow.rootViewController = vc;
        ALShieldWindow.hidden = NO;
        [ALShieldWindow makeKeyAndVisible];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.18 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIApplication *app = UIApplication.sharedApplication;
            SEL suspend = NSSelectorFromString(@"suspend");
            if ([app respondsToSelector:suspend]) {
                ((void(*)(id, SEL))objc_msgSend)(app, suspend);
            } else {
                exit(0);
            }
            ALHandlingBlock = NO;
        });
    });
}

static void ALCheckCurrentApplication(void) {
    if (!ALRepairModeEnabled()) return;
    NSString *bundleID = NSBundle.mainBundle.bundleIdentifier;
    if (!ALIsBundleAllowed(bundleID)) ALShowShieldAndSuspend();
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

        dispatch_async(dispatch_get_main_queue(), ^{ ALCheckCurrentApplication(); });
    }
}
