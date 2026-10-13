#import "ALAppSelectionController.h"
#import <Preferences/PSSpecifier.h>
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <objc/message.h>
#import "ALPreferences.h"

@interface UIImage (ALApplicationIcon)
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier
                                                format:(NSInteger)format
                                                 scale:(CGFloat)scale;
@end

@implementation ALAppSelectionController

- (NSArray *)specifiers {
    if (_specifiers) return _specifiers;

    NSMutableArray *items = [NSMutableArray array];
    PSSpecifier *group = [PSSpecifier groupSpecifierWithName:@"允许维修人员使用的 App"];
    [group setProperty:@"打开开关后，该 App 在维修模式中可以正常使用。AegisRepair 始终允许使用。" forKey:@"footerText"];
    [items addObject:group];

    for (NSDictionary *application in [self installedApplications]) {
        NSString *name = application[@"name"];
        NSString *bundleID = application[@"bundleID"];
        PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:name
                                                                 target:self
                                                                    set:@selector(setAllowed:specifier:)
                                                                    get:@selector(isAllowed:)
                                                                 detail:nil
                                                                   cell:PSSwitchCell
                                                                   edit:nil];
        specifier.identifier = bundleID;
        [specifier setProperty:bundleID forKey:@"bundleID"];

        UIImage *icon = [self iconForBundleIdentifier:bundleID];
        if (icon) [specifier setProperty:icon forKey:@"iconImage"];
        [items addObject:specifier];
    }

    _specifiers = items;
    return _specifiers;
}

- (NSArray<NSDictionary *> *)installedApplications {
    dlopen("/System/Library/Frameworks/MobileCoreServices.framework/MobileCoreServices", RTLD_LAZY);
    dlopen("/System/Library/Frameworks/CoreServices.framework/CoreServices", RTLD_LAZY);
    Class workspaceClass = NSClassFromString(@"LSApplicationWorkspace");
    SEL defaultSelector = NSSelectorFromString(@"defaultWorkspace");
    if (!workspaceClass || ![workspaceClass respondsToSelector:defaultSelector]) return @[];

    id workspace = ((id (*)(id, SEL))objc_msgSend)(workspaceClass, defaultSelector);
    SEL applicationsSelector = NSSelectorFromString(@"allInstalledApplications");
    if (![workspace respondsToSelector:applicationsSelector]) {
        applicationsSelector = NSSelectorFromString(@"allApplications");
    }
    if (![workspace respondsToSelector:applicationsSelector]) return @[];

    NSArray *proxies = ((id (*)(id, SEL))objc_msgSend)(workspace, applicationsSelector);
    NSMutableArray<NSDictionary *> *applications = [NSMutableArray array];
    NSMutableSet<NSString *> *seen = [NSMutableSet set];

    for (id proxy in proxies) {
        NSString *bundleID = [self stringValueForKey:@"applicationIdentifier" object:proxy];
        NSString *name = [self stringValueForKey:@"localizedName" object:proxy];
        NSString *type = [self stringValueForKey:@"applicationType" object:proxy];
        if (!bundleID.length || !name.length || [seen containsObject:bundleID]) continue;
        if ([bundleID isEqualToString:@"com.aegislock.repair"] ||
            [bundleID isEqualToString:@"com.apple.springboard"]) continue;
        if (type.length && ![type isEqualToString:@"User"] && ![type isEqualToString:@"System"]) continue;

        [seen addObject:bundleID];
        [applications addObject:@{@"name": name, @"bundleID": bundleID}];
    }

    [applications sortUsingComparator:^NSComparisonResult(NSDictionary *left, NSDictionary *right) {
        return [left[@"name"] localizedStandardCompare:right[@"name"]];
    }];
    return applications;
}

- (NSString *)stringValueForKey:(NSString *)key object:(id)object {
    @try {
        id value = [object valueForKey:key];
        return [value isKindOfClass:NSString.class] ? value : nil;
    } @catch (__unused NSException *exception) {
        return nil;
    }
}

- (UIImage *)iconForBundleIdentifier:(NSString *)bundleID {
    SEL selector = @selector(_applicationIconImageForBundleIdentifier:format:scale:);
    if (![UIImage respondsToSelector:selector]) return nil;
    return [UIImage _applicationIconImageForBundleIdentifier:bundleID
                                                       format:2
                                                        scale:UIScreen.mainScreen.scale];
}

- (NSNumber *)isAllowed:(PSSpecifier *)specifier {
    NSString *bundleID = [specifier propertyForKey:@"bundleID"];
    return @([ALAllowedBundleIDs() containsObject:bundleID]);
}

- (void)setAllowed:(NSNumber *)allowed specifier:(PSSpecifier *)specifier {
    NSString *bundleID = [specifier propertyForKey:@"bundleID"];
    if (!bundleID.length) return;

    NSMutableOrderedSet<NSString *> *selection = [NSMutableOrderedSet orderedSetWithArray:ALAllowedBundleIDs()];
    [selection removeObject:@"com.aegislock.repair"];
    [selection removeObject:@"com.apple.springboard"];
    if (allowed.boolValue) [selection addObject:bundleID];
    else [selection removeObject:bundleID];
    ALSetAllowedBundleIDs(selection.array);
}

@end
