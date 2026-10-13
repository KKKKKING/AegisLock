#import "ALPreferences.h"
#import <CommonCrypto/CommonDigest.h>
#import <notify.h>
#import <Security/Security.h>

NSString * const ALPrefsDomain = @"com.aegislock.repairmode";
NSString * const ALPrefsChangedNotification = @"com.aegislock.repairmode/preferences.changed";

static NSDictionary *ALReadPrefs(void) {
    CFPreferencesAppSynchronize((__bridge CFStringRef)ALPrefsDomain);
    CFArrayRef keys = CFPreferencesCopyKeyList((__bridge CFStringRef)ALPrefsDomain,
                                                kCFPreferencesCurrentUser,
                                                kCFPreferencesAnyHost);
    if (!keys) return @{};
    CFDictionaryRef values = CFPreferencesCopyMultiple(keys,
                                                        (__bridge CFStringRef)ALPrefsDomain,
                                                        kCFPreferencesCurrentUser,
                                                        kCFPreferencesAnyHost);
    CFRelease(keys);
    return CFBridgingRelease(values) ?: @{};
}

static void ALWrite(NSString *key, id value) {
    CFPreferencesSetValue((__bridge CFStringRef)key,
                          (__bridge CFPropertyListRef)value,
                          (__bridge CFStringRef)ALPrefsDomain,
                          kCFPreferencesCurrentUser,
                          kCFPreferencesAnyHost);
    CFPreferencesAppSynchronize((__bridge CFStringRef)ALPrefsDomain);
    notify_post(ALPrefsChangedNotification.UTF8String);
}

static NSString *ALHex(NSData *data) {
    const unsigned char *bytes = data.bytes;
    NSMutableString *out = [NSMutableString stringWithCapacity:data.length * 2];
    for (NSUInteger i = 0; i < data.length; i++) [out appendFormat:@"%02x", bytes[i]];
    return out;
}

static NSString *ALHash(NSString *passcode, NSString *saltHex) {
    NSString *joined = [NSString stringWithFormat:@"%@:%@", saltHex ?: @"", passcode ?: @""];
    NSData *data = [joined dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, digest);
    return ALHex([NSData dataWithBytes:digest length:sizeof(digest)]);
}

BOOL ALRepairModeEnabled(void) {
    return [ALReadPrefs()[@"repairEnabled"] boolValue];
}

NSArray<NSString *> *ALAllowedBundleIDs(void) {
    NSString *raw = ALReadPrefs()[@"allowedBundleIDs"];
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithArray:@[
        @"com.aegislock.repair",
        @"com.apple.springboard"
    ]];
    if ([raw isKindOfClass:NSString.class]) {
        NSCharacterSet *trim = NSCharacterSet.whitespaceAndNewlineCharacterSet;
        for (NSString *part in [raw componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@",;\n"]]) {
            NSString *value = [part stringByTrimmingCharactersInSet:trim];
            if (value.length) [set addObject:value];
        }
    }
    return set.array;
}

BOOL ALIsBundleAllowed(NSString *bundleID) {
    if (!bundleID.length) return YES;
    if ([bundleID isEqualToString:@"com.apple.springboard"]) return YES;
    if ([bundleID isEqualToString:@"com.aegislock.repair"]) return YES;
    return [ALAllowedBundleIDs() containsObject:bundleID];
}

BOOL ALHasPasscode(void) {
    NSDictionary *p = ALReadPrefs();
    return [p[@"passcodeHash"] isKindOfClass:NSString.class] && [p[@"passcodeSalt"] isKindOfClass:NSString.class];
}

BOOL ALVerifyPasscode(NSString *passcode) {
    NSDictionary *p = ALReadPrefs();
    NSString *hash = p[@"passcodeHash"];
    NSString *salt = p[@"passcodeSalt"];
    if (!hash.length || !salt.length) return NO;
    NSString *candidate = ALHash(passcode, salt);
    NSData *a = [hash dataUsingEncoding:NSUTF8StringEncoding];
    NSData *b = [candidate dataUsingEncoding:NSUTF8StringEncoding];
    if (a.length != b.length) return NO;
    const uint8_t *pa = a.bytes, *pb = b.bytes;
    uint8_t diff = 0;
    for (NSUInteger i = 0; i < a.length; i++) diff |= (pa[i] ^ pb[i]);
    return diff == 0;
}

BOOL ALSetPasscode(NSString *passcode) {
    if (passcode.length < 4 || passcode.length > 12) return NO;
    for (NSUInteger i = 0; i < passcode.length; i++) {
        if (![[NSCharacterSet decimalDigitCharacterSet] characterIsMember:[passcode characterAtIndex:i]]) return NO;
    }
    uint8_t saltBytes[16];
    if (SecRandomCopyBytes(kSecRandomDefault, sizeof(saltBytes), saltBytes) != errSecSuccess) return NO;
    NSString *salt = ALHex([NSData dataWithBytes:saltBytes length:sizeof(saltBytes)]);
    ALWrite(@"passcodeSalt", salt);
    ALWrite(@"passcodeHash", ALHash(passcode, salt));
    return YES;
}

void ALSetRepairMode(BOOL enabled) {
    ALWrite(@"repairEnabled", @(enabled));
}

NSString *ALBlockedMessage(void) {
    NSString *s = ALReadPrefs()[@"blockedMessage"];
    return s.length ? s : @"维修模式已开启，此应用不可访问";
}
