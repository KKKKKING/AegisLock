#import "RootListController.h"
#import <Preferences/PSSpecifier.h>
#import <UIKit/UIKit.h>
#import "ALPreferences.h"

@implementation RootListController

- (NSArray *)specifiers {
    if (!_specifiers) _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    return _specifiers;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    if ([key isEqualToString:@"repairEnabled"]) {
        BOOL enable = [value boolValue];
        if (enable) {
            if (!ALHasPasscode()) {
                [self showInfo:@"请先设置维修模式独立密码。"];
                [self reloadSpecifier:specifier animated:YES];
                return;
            }
            ALSetRepairMode(YES);
            [self reloadSpecifier:specifier animated:YES];
            return;
        }
        if (ALRepairModeEnabled()) {
            [self promptForPasscodeWithTitle:@"退出维修模式" completion:^(NSString *pass) {
                if (ALVerifyPasscode(pass)) {
                    ALSetRepairMode(NO);
                    [self reloadSpecifier:specifier animated:YES];
                } else {
                    [self showInfo:@"密码错误。维修模式保持开启。"];
                    [self reloadSpecifier:specifier animated:YES];
                }
            }];
            return;
        }
    }
    [super setPreferenceValue:value specifier:specifier];
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    if ([key isEqualToString:@"repairEnabled"]) return @(ALRepairModeEnabled());
    return [super readPreferenceValue:specifier];
}

- (void)setRepairPasscode {
    void (^createNew)(void) = ^{
        [self promptForPasscodeWithTitle:@"设置 4–12 位数字密码" completion:^(NSString *first) {
            if (first.length < 4 || first.length > 12) { [self showInfo:@"密码必须是 4–12 位数字。"] ; return; }
            [self promptForPasscodeWithTitle:@"再次输入新密码" completion:^(NSString *second) {
                if (![first isEqualToString:second]) { [self showInfo:@"两次输入不一致。"] ; return; }
                if (ALSetPasscode(first)) [self showInfo:@"独立密码已保存。它与设备密码、Face ID 完全分开。"];
                else [self showInfo:@"密码必须是 4–12 位数字。"];
            }];
        }];
    };

    if (!ALHasPasscode()) { createNew(); return; }
    [self promptForPasscodeWithTitle:@"输入当前维修模式密码" completion:^(NSString *old) {
        if (!ALVerifyPasscode(old)) { [self showInfo:@"当前密码错误。"] ; return; }
        createNew();
    }];
}

- (void)disableRepairMode {
    if (!ALRepairModeEnabled()) { [self showInfo:@"维修模式当前未开启。"] ; return; }
    [self promptForPasscodeWithTitle:@"输入独立密码退出" completion:^(NSString *pass) {
        if (ALVerifyPasscode(pass)) { ALSetRepairMode(NO); [self reloadSpecifiers]; [self showInfo:@"维修模式已关闭。"] ; }
        else [self showInfo:@"密码错误。"];
    }];
}

- (void)promptForPasscodeWithTitle:(NSString *)title completion:(void (^)(NSString *))completion {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.secureTextEntry = YES;
        tf.keyboardType = UIKeyboardTypeNumberPad;
        tf.textContentType = UITextContentTypePassword;
    }];
    [a addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        completion(a.textFields.firstObject.text ?: @"");
    }]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)showInfo:(NSString *)message {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"AegisLock" message:message preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}
@end
