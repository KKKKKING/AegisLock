#import "ALAppSelectionController.h"
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <objc/message.h>
#import "ALPreferences.h"

@interface UIImage (ALApplicationIcon)
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier
                                                format:(NSInteger)format
                                                 scale:(CGFloat)scale;
@end

@interface ALApplicationCell : UITableViewCell
@property (nonatomic, strong) UIImageView *applicationIconView;
@property (nonatomic, strong) UILabel *applicationNameLabel;
@property (nonatomic, strong) UILabel *bundleIdentifierLabel;
@property (nonatomic, strong) UISwitch *allowSwitch;
@property (nonatomic, copy) NSString *bundleIdentifier;
@end

@implementation ALApplicationCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) return nil;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;

    _applicationIconView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _applicationIconView.contentMode = UIViewContentModeScaleAspectFill;
    _applicationIconView.clipsToBounds = YES;
    _applicationIconView.layer.cornerRadius = 12.0;
    [self.contentView addSubview:_applicationIconView];

    _applicationNameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _applicationNameLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold];
    _applicationNameLabel.textColor = UIColor.labelColor;
    [self.contentView addSubview:_applicationNameLabel];

    _bundleIdentifierLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _bundleIdentifierLabel.font = [UIFont systemFontOfSize:12.5];
    _bundleIdentifierLabel.textColor = UIColor.secondaryLabelColor;
    _bundleIdentifierLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    [self.contentView addSubview:_bundleIdentifierLabel];

    _allowSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    [self.contentView addSubview:_allowSwitch];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat height = CGRectGetHeight(self.contentView.bounds);
    CGFloat width = CGRectGetWidth(self.contentView.bounds);
    CGFloat iconSize = 52.0;
    self.applicationIconView.frame = CGRectMake(15.0, (height - iconSize) / 2.0, iconSize, iconSize);
    [self.allowSwitch sizeToFit];
    CGFloat switchWidth = CGRectGetWidth(self.allowSwitch.bounds);
    self.allowSwitch.frame = CGRectMake(width - switchWidth - 15.0,
                                        (height - CGRectGetHeight(self.allowSwitch.bounds)) / 2.0,
                                        switchWidth,
                                        CGRectGetHeight(self.allowSwitch.bounds));
    CGFloat textLeft = CGRectGetMaxX(self.applicationIconView.frame) + 14.0;
    CGFloat textWidth = MAX(20.0, CGRectGetMinX(self.allowSwitch.frame) - textLeft - 12.0);
    self.applicationNameLabel.frame = CGRectMake(textLeft, 16.0, textWidth, 22.0);
    self.bundleIdentifierLabel.frame = CGRectMake(textLeft, 41.0, textWidth, 18.0);
}

@end

@interface ALAppSelectionController () <UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, copy) NSArray<NSDictionary *> *applications;
@property (nonatomic, copy) NSArray<NSDictionary *> *filteredApplications;
@property (nonatomic, strong) NSMutableDictionary<NSString *, UIImage *> *iconCache;
@end

@implementation ALAppSelectionController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"允许使用的 App";
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.iconCache = [NSMutableDictionary dictionary];
    self.applications = [self installedApplications];
    self.filteredApplications = self.applications;

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 76.0;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.tableView.separatorInset = UIEdgeInsetsMake(0.0, 81.0, 0.0, 0.0);
    [self.tableView registerClass:ALApplicationCell.class forCellReuseIdentifier:@"Application"];
    [self.view addSubview:self.tableView];

    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.placeholder = @"名称或标识符";
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    self.definesPresentationContext = YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 2; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self applicationsInSection:section].count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"用户安装的 App" : @"系统 App";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return section == 1 ? @"所有 App 默认禁止打开。开启开关后，该 App 才能在维修模式中使用；AegisRepair 始终可用。" : nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ALApplicationCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Application" forIndexPath:indexPath];
    NSDictionary *application = [self applicationsInSection:indexPath.section][indexPath.row];
    NSString *bundleID = application[@"bundleID"];
    cell.applicationNameLabel.text = application[@"name"];
    cell.bundleIdentifierLabel.text = bundleID;
    cell.bundleIdentifier = bundleID;
    cell.applicationIconView.image = [self iconForBundleIdentifier:bundleID];
    [cell.allowSwitch removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
    cell.allowSwitch.on = [ALAllowedBundleIDs() containsObject:bundleID];
    [cell.allowSwitch addTarget:self action:@selector(allowSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    return cell;
}

- (NSArray<NSDictionary *> *)applicationsInSection:(NSInteger)section {
    NSString *type = section == 0 ? @"User" : @"System";
    return [self.filteredApplications filteredArrayUsingPredicate:
            [NSPredicate predicateWithFormat:@"type == %@", type]];
}

- (void)allowSwitchChanged:(UISwitch *)sender {
    UIView *ancestor = sender;
    while (ancestor && ![ancestor isKindOfClass:ALApplicationCell.class]) ancestor = ancestor.superview;
    NSString *bundleID = [(ALApplicationCell *)ancestor bundleIdentifier];
    if (!bundleID.length) return;
    NSMutableOrderedSet<NSString *> *selection = [NSMutableOrderedSet orderedSetWithArray:ALAllowedBundleIDs()];
    [selection removeObject:@"com.aegislock.repair"];
    [selection removeObject:@"com.apple.springboard"];
    if (sender.on) [selection addObject:bundleID];
    else [selection removeObject:bundleID];
    ALSetAllowedBundleIDs(selection.array);
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *query = [searchController.searchBar.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!query.length) {
        self.filteredApplications = self.applications;
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *application, NSDictionary *bindings) {
            return [application[@"name"] localizedCaseInsensitiveContainsString:query] ||
                   [application[@"bundleID"] localizedCaseInsensitiveContainsString:query];
        }];
        self.filteredApplications = [self.applications filteredArrayUsingPredicate:predicate];
    }
    if (!self.filteredApplications.count) {
        UILabel *empty = [[UILabel alloc] initWithFrame:self.tableView.bounds];
        empty.text = @"没有找到匹配的 App";
        empty.textAlignment = NSTextAlignmentCenter;
        empty.textColor = UIColor.secondaryLabelColor;
        self.tableView.backgroundView = empty;
    } else {
        self.tableView.backgroundView = nil;
    }
    [self.tableView reloadData];
}

- (NSArray<NSDictionary *> *)installedApplications {
    dlopen("/System/Library/Frameworks/MobileCoreServices.framework/MobileCoreServices", RTLD_LAZY);
    dlopen("/System/Library/Frameworks/CoreServices.framework/CoreServices", RTLD_LAZY);
    Class workspaceClass = NSClassFromString(@"LSApplicationWorkspace");
    SEL defaultSelector = NSSelectorFromString(@"defaultWorkspace");
    if (!workspaceClass || ![workspaceClass respondsToSelector:defaultSelector]) return @[];
    id workspace = ((id (*)(id, SEL))objc_msgSend)(workspaceClass, defaultSelector);
    SEL applicationsSelector = NSSelectorFromString(@"allInstalledApplications");
    if (![workspace respondsToSelector:applicationsSelector]) applicationsSelector = NSSelectorFromString(@"allApplications");
    if (![workspace respondsToSelector:applicationsSelector]) return @[];

    NSArray *proxies = ((id (*)(id, SEL))objc_msgSend)(workspace, applicationsSelector);
    NSMutableDictionary<NSString *, NSDictionary *> *bestByName = [NSMutableDictionary dictionary];
    NSMutableSet<NSString *> *seenBundleIDs = [NSMutableSet set];
    for (id proxy in proxies) {
        NSString *bundleID = [self stringValueForKey:@"applicationIdentifier" object:proxy];
        NSString *name = [self stringValueForKey:@"localizedName" object:proxy];
        NSString *type = [self stringValueForKey:@"applicationType" object:proxy];
        NSURL *bundleURL = [self URLValueForKey:@"bundleURL" object:proxy];
        if (!bundleID.length || !name.length || [seenBundleIDs containsObject:bundleID]) continue;
        [seenBundleIDs addObject:bundleID];
        if ([bundleID isEqualToString:@"com.aegislock.repair"] || [bundleID isEqualToString:@"com.apple.springboard"]) continue;
        if (type.length && ![type isEqualToString:@"User"] && ![type isEqualToString:@"System"]) continue;
        if (![self isVisibleLaunchableApplication:proxy bundleID:bundleID bundleURL:bundleURL]) continue;

        BOOL userApplication = [type isEqualToString:@"User"] ||
                               [bundleURL.path.lowercaseString containsString:@"/var/containers/bundle/application/"];
        NSString *category = userApplication ? @"User" : @"System";
        NSInteger score = userApplication ? 30 : 10;
        if ([bundleID isEqualToString:@"com.apple.Preferences"] || [bundleID isEqualToString:@"com.apple.MobileAddressBook"]) score += 100;
        if ([self iconForBundleIdentifier:bundleID]) score += 5;
        NSString *nameKey = name.lowercaseString;
        NSDictionary *candidate = @{ @"name": name, @"bundleID": bundleID, @"type": category, @"score": @(score) };
        NSDictionary *existing = bestByName[nameKey];
        if (!existing || [candidate[@"score"] integerValue] > [existing[@"score"] integerValue]) bestByName[nameKey] = candidate;
    }

    NSMutableArray<NSDictionary *> *applications = [bestByName.allValues mutableCopy];
    [applications sortUsingComparator:^NSComparisonResult(NSDictionary *left, NSDictionary *right) {
        return [left[@"name"] localizedStandardCompare:right[@"name"]];
    }];
    return applications;
}

- (BOOL)isVisibleLaunchableApplication:(id)proxy bundleID:(NSString *)bundleID bundleURL:(NSURL *)bundleURL {
    if (!bundleURL || ![bundleURL.pathExtension.lowercaseString isEqualToString:@"app"]) return NO;
    NSString *path = bundleURL.path.lowercaseString;
    NSString *identifier = bundleID.lowercaseString;
    if ([path containsString:@".appex/"] || [path containsString:@"/plugins/"]) return NO;
    NSArray<NSString *> *markers = @[@"viewservice", @"uiservice", @"remoteui", @"splashscreen",
                                      @"wallpaper", @"checkerboard", @"setupassistant", @"diagnosticsreporter"];
    for (NSString *marker in markers) if ([identifier containsString:marker]) return NO;
    if ([self boolValueForKey:@"isPlaceholder" object:proxy]) return NO;

    NSDictionary *info = [NSBundle bundleWithURL:bundleURL].infoDictionary;
    if (!info.count) info = [NSDictionary dictionaryWithContentsOfURL:[bundleURL URLByAppendingPathComponent:@"Info.plist"]];
    if ([info[@"LSUIElement"] boolValue] || info[@"NSExtension"]) return NO;
    NSString *packageType = info[@"CFBundlePackageType"];
    if (packageType.length && ![packageType isEqualToString:@"APPL"]) return NO;
    NSArray *appTags = [info[@"SBAppTags"] isKindOfClass:NSArray.class] ? info[@"SBAppTags"] : @[];
    for (id tag in appTags) {
        if ([tag isKindOfClass:NSString.class] && [tag caseInsensitiveCompare:@"hidden"] == NSOrderedSame) return NO;
    }
    return YES;
}

- (NSString *)stringValueForKey:(NSString *)key object:(id)object {
    @try {
        id value = [object valueForKey:key];
        return [value isKindOfClass:NSString.class] ? value : nil;
    } @catch (__unused NSException *exception) { return nil; }
}

- (NSURL *)URLValueForKey:(NSString *)key object:(id)object {
    @try {
        id value = [object valueForKey:key];
        return [value isKindOfClass:NSURL.class] ? value : nil;
    } @catch (__unused NSException *exception) { return nil; }
}

- (BOOL)boolValueForKey:(NSString *)key object:(id)object {
    @try {
        id value = [object valueForKey:key];
        return [value respondsToSelector:@selector(boolValue)] && [value boolValue];
    } @catch (__unused NSException *exception) { return NO; }
}

- (UIImage *)iconForBundleIdentifier:(NSString *)bundleID {
    UIImage *cached = self.iconCache[bundleID];
    if (cached) return cached;
    SEL selector = @selector(_applicationIconImageForBundleIdentifier:format:scale:);
    if (![UIImage respondsToSelector:selector]) return nil;
    UIImage *icon = [UIImage _applicationIconImageForBundleIdentifier:bundleID format:2 scale:UIScreen.mainScreen.scale];
    if (icon) self.iconCache[bundleID] = icon;
    return icon;
}

@end
