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

        UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
        closeButton.translatesAutoresizingMaskIntoConstraints = NO;
        [closeButton setTitle:@"返回桌面" forState:UIControlStateNormal];
        closeButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
        closeButton.backgroundColor = UIColor.systemBlueColor;
        [closeButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        closeButton.layer.cornerRadius = 12;
        [closeButton addAction:[UIAction actionWithHandler:^(__unused UIAction *action) {
            ALSuspendApplication();
        }] forControlEvents:UIControlEventTouchUpInside];

        [vc.view addSubview:icon];
        [vc.view addSubview:title];
        [vc.view addSubview:detail];
        [vc.view addSubview:closeButton];
        [NSLayoutConstraint activateConstraints:@[
            [icon.centerXAnchor constraintEqualToAnchor:vc.view.centerXAnchor],
            [icon.centerYAnchor constraintEqualToAnchor:vc.view.centerYAnchor constant:-55],
            [title.topAnchor constraintEqualToAnchor:icon.bottomAnchor constant:18],
            [title.leadingAnchor constraintEqualToAnchor:vc.view.leadingAnchor constant:28],
            [title.trailingAnchor constraintEqualToAnchor:vc.view.trailingAnchor constant:-28],
            [detail.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:10],
            [detail.leadingAnchor constraintEqualToAnchor:vc.view.leadingAnchor constant:28],
            [detail.trailingAnchor constraintEqualToAnchor:vc.view.trailingAnchor constant:-28],
            [closeButton.topAnchor constraintEqualToAnchor:detail.bottomAnchor constant:28],
            [closeButton.centerXAnchor constraintEqualToAnchor:vc.view.centerXAnchor],
            [closeButton.widthAnchor constraintEqualToConstant:180],
            [closeButton.heightAnchor constraintEqualToConstant:48]
        ]];

        ALShieldWindow.rootViewController = vc;
        ALShieldWindow.hidden = NO;
        [ALShieldWindow makeKeyAndVisible];
    });
}

static void ALCheckCurrentApplication(void) {
    if (!ALRepairModeEnabled()) {
        ALHideShield();
        return;
    }
    NSString *bundleID = NSBundle.mainBundle.bundleIdentifier;
    if (!ALIsBundleAllowed(bundleID)) ALShowShieldAndSuspend();
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
