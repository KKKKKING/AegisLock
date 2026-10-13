#import <UIKit/UIKit.h>
@interface ScreenTestViewController : UIViewController @end
@implementation ScreenTestViewController {
    NSArray<UIColor *> *_colors; NSArray<NSString *> *_names; NSInteger _index; UILabel *_label;
}
- (void)viewDidLoad { [super viewDidLoad]; self.title=@"屏幕测试"; _colors=@[UIColor.redColor,UIColor.greenColor,UIColor.blueColor,UIColor.whiteColor,UIColor.blackColor]; _names=@[@"红",@"绿",@"蓝",@"白",@"黑"]; _label=[UILabel new]; _label.translatesAutoresizingMaskIntoConstraints=NO; _label.font=[UIFont boldSystemFontOfSize:28]; _label.textAlignment=NSTextAlignmentCenter; [self.view addSubview:_label]; [NSLayoutConstraint activateConstraints:@[[_label.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],[_label.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]]]; UITapGestureRecognizer *tap=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(next)]; [self.view addGestureRecognizer:tap]; [self apply]; }
- (void)next { _index=(_index+1)%_colors.count; [self apply]; }
- (void)apply { self.view.backgroundColor=_colors[_index]; _label.text=[NSString stringWithFormat:@"%@色\n轻点切换",_names[_index]]; _label.numberOfLines=0; _label.textColor=(_index==3?UIColor.blackColor:UIColor.whiteColor); }
@end
