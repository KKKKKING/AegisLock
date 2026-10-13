#import "TouchTestViewController.h"
@interface ALDrawView : UIView @property(nonatomic,strong) UIBezierPath *path; @end
@implementation ALDrawView
- (instancetype)initWithFrame:(CGRect)frame { if((self=[super initWithFrame:frame])){ self.backgroundColor=UIColor.systemBackgroundColor; self.path=[UIBezierPath bezierPath]; self.path.lineWidth=4; self.multipleTouchEnabled=YES; } return self; }
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { UITouch *t=touches.anyObject; [self.path moveToPoint:[t locationInView:self]]; [self setNeedsDisplay]; }
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { UITouch *t=touches.anyObject; [self.path addLineToPoint:[t locationInView:self]]; [self setNeedsDisplay]; }
- (void)drawRect:(CGRect)rect { [UIColor.labelColor setStroke]; [self.path stroke]; }
@end
@implementation TouchTestViewController
- (void)loadView { self.view=[[ALDrawView alloc] initWithFrame:UIScreen.mainScreen.bounds]; }
- (void)viewDidLoad { [super viewDidLoad]; self.title=@"触摸测试"; self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"清空" style:UIBarButtonItemStylePlain target:self action:@selector(clear)]; }
- (void)clear { ALDrawView *v=(ALDrawView *)self.view; v.path=[UIBezierPath bezierPath]; v.path.lineWidth=4; [v setNeedsDisplay]; }
@end
