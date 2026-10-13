#import "ALAccessLogController.h"
#import <UIKit/UIKit.h>
#import "ALPreferences.h"

@interface UIImage (ALAccessLogIcon)
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier
                                                format:(NSInteger)format
                                                 scale:(CGFloat)scale;
@end

@interface ALAccessLogController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<NSDictionary *> *logs;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@end

@implementation ALAccessLogController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"操作日志";
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.dateFormatter = [NSDateFormatter new];
    self.dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"zh_CN"];
    self.dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 76.0;
    self.tableView.separatorInset = UIEdgeInsetsMake(0.0, 72.0, 0.0, 0.0);
    [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.logs = [ALAccessLogs() sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *left, NSDictionary *right) {
        return [right[@"timestamp"] compare:left[@"timestamp"]];
    }];
    if (!self.logs.count) {
        UILabel *empty = [[UILabel alloc] initWithFrame:self.tableView.bounds];
        empty.text = @"暂无拦截记录";
        empty.textAlignment = NSTextAlignmentCenter;
        empty.textColor = UIColor.secondaryLabelColor;
        self.tableView.backgroundView = empty;
    } else {
        self.tableView.backgroundView = nil;
    }
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.logs.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"被拦截的启动记录";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return @"日志按发生时间永久保存，只能查看，不能在 AegisLock 中删除。";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"AccessLog";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    NSDictionary *entry = self.logs[indexPath.row];
    NSString *bundleID = entry[@"bundleID"];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[entry[@"timestamp"] doubleValue]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = entry[@"appName"] ?: bundleID;
    cell.textLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@\n%@", [self.dateFormatter stringFromDate:date], bundleID];
    cell.detailTextLabel.numberOfLines = 2;
    cell.detailTextLabel.textColor = UIColor.secondaryLabelColor;
    if ([UIImage respondsToSelector:@selector(_applicationIconImageForBundleIdentifier:format:scale:)]) {
        cell.imageView.image = [UIImage _applicationIconImageForBundleIdentifier:bundleID format:1 scale:UIScreen.mainScreen.scale];
        cell.imageView.layer.cornerRadius = 8.0;
        cell.imageView.clipsToBounds = YES;
    }
    return cell;
}

@end
