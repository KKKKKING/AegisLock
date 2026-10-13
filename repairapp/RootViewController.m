#import "RootViewController.h"
#import "TouchTestViewController.h"
#import "ScreenTestViewController.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import <AVFoundation/AVFoundation.h>
#import <math.h>
#import <notify.h>
#import "ALPreferences.h"

@interface RootViewController ()
@property(nonatomic, strong) LAContext *authenticationContext;
@property(nonatomic, strong) AVAudioPlayer *tonePlayer;
@end

static void ALAppendUInt16(NSMutableData *data, uint16_t value) {
    uint16_t littleEndian = CFSwapInt16HostToLittle(value);
    [data appendBytes:&littleEndian length:sizeof(littleEndian)];
}

static void ALAppendUInt32(NSMutableData *data, uint32_t value) {
    uint32_t littleEndian = CFSwapInt32HostToLittle(value);
    [data appendBytes:&littleEndian length:sizeof(littleEndian)];
}

static NSData *ALToneWaveData(void) {
    const uint32_t sampleRate = 44100;
    const uint16_t channelCount = 1;
    const uint16_t bitsPerSample = 16;
    const NSTimeInterval duration = 0.8;
    const uint32_t sampleCount = (uint32_t)(sampleRate * duration);
    const uint32_t dataSize = sampleCount * channelCount * (bitsPerSample / 8);
    NSMutableData *wave = [NSMutableData dataWithCapacity:44 + dataSize];

    [wave appendBytes:"RIFF" length:4];
    ALAppendUInt32(wave, 36 + dataSize);
    [wave appendBytes:"WAVE" length:4];
    [wave appendBytes:"fmt " length:4];
    ALAppendUInt32(wave, 16);
    ALAppendUInt16(wave, 1);
    ALAppendUInt16(wave, channelCount);
    ALAppendUInt32(wave, sampleRate);
    ALAppendUInt32(wave, sampleRate * channelCount * (bitsPerSample / 8));
    ALAppendUInt16(wave, channelCount * (bitsPerSample / 8));
    ALAppendUInt16(wave, bitsPerSample);
    [wave appendBytes:"data" length:4];
    ALAppendUInt32(wave, dataSize);

    for (uint32_t index = 0; index < sampleCount; index++) {
        double position = (double)index / sampleRate;
        double fadeIn = MIN(1.0, position / 0.03);
        double fadeOut = MIN(1.0, (duration - position) / 0.08);
        double envelope = MAX(0.0, MIN(fadeIn, fadeOut));
        int16_t sample = (int16_t)(sin(2.0 * M_PI * 880.0 * position) * 0.55 * envelope * INT16_MAX);
        ALAppendUInt16(wave, (uint16_t)sample);
    }
    return wave;
}

@implementation RootViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"AegisRepair";
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    self.navigationController.navigationBar.prefersLargeTitles = YES;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return 7; }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { return @"安全的维修测试"; }
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section { return @"Face ID 测试只验证传感器与认证流程，不开放“设置”App，也不会显示你的系统密码。"; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    NSArray *titles = @[@"测试 Face ID", @"测试前/后摄像头", @"测试震动/触感", @"测试扬声器提示音", @"屏幕纯色测试", @"触摸轨迹测试", @"退出维修模式"];
    NSArray *subs = @[@"调用系统 LocalAuthentication", @"不会自动保存照片", @"触发系统触觉反馈", @"播放短提示音", @"红/绿/蓝/白/黑循环", @"检查触控断点和区域", @"只接受 AegisLock 独立密码"];
    c.textLabel.text = titles[indexPath.row]; c.detailTextLabel.text = subs[indexPath.row]; c.accessoryType = UITableViewCellAccessoryDisclosureIndicator; return c;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case 0: [self testFaceID]; break;
        case 1: [self testCamera]; break;
        case 2: [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy] impactOccurred]; break;
        case 3: [self testSpeaker]; break;
        case 4: [self.navigationController pushViewController:[ScreenTestViewController new] animated:YES]; break;
        case 5: [self.navigationController pushViewController:[TouchTestViewController new] animated:YES]; break;
        case 6: [self promptExitRepairMode]; break;
    }
}
- (void)testFaceID {
    LAContext *ctx = [LAContext new];
    self.authenticationContext = ctx;
    NSError *err = nil;
    if (![ctx canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&err]) { [self alert:@"Face ID/Touch ID 当前不可用" detail:err.localizedDescription ?: @""]; return; }
    [ctx evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:@"维修测试：验证生物识别传感器是否正常" reply:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.authenticationContext = nil;
            [self alert:(success ? @"测试通过" : @"测试失败") detail:(success ? @"生物识别认证成功。" : (error.localizedDescription ?: @"认证失败"))];
        });
    }];
}
- (void)testSpeaker {
    NSError *sessionError = nil;
    AVAudioSession *session = AVAudioSession.sharedInstance;
    [session setCategory:AVAudioSessionCategoryPlayback mode:AVAudioSessionModeDefault options:0 error:&sessionError];
    if (!sessionError) [session setActive:YES error:&sessionError];
    if (sessionError) {
        [self alert:@"扬声器测试失败" detail:sessionError.localizedDescription ?: @"无法启动音频会话。"];
        return;
    }

    NSError *playerError = nil;
    self.tonePlayer = [[AVAudioPlayer alloc] initWithData:ALToneWaveData() error:&playerError];
    if (!self.tonePlayer || playerError) {
        [self alert:@"扬声器测试失败" detail:playerError.localizedDescription ?: @"无法生成测试音。"];
        return;
    }
    self.tonePlayer.volume = 1.0;
    [self.tonePlayer prepareToPlay];
    if (![self.tonePlayer play]) [self alert:@"扬声器测试失败" detail:@"无法播放测试音。"];
}
- (void)testCamera {
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) { [self alert:@"摄像头不可用" detail:@""]; return; }
    UIImagePickerController *p = [UIImagePickerController new]; p.sourceType = UIImagePickerControllerSourceTypeCamera; p.delegate = self; p.allowsEditing = NO; [self presentViewController:p animated:YES completion:nil];
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info { [picker dismissViewControllerAnimated:YES completion:nil]; }
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker { [picker dismissViewControllerAnimated:YES completion:nil]; }

- (void)promptExitRepairMode {
    UIAlertController *a=[UIAlertController alertControllerWithTitle:@"退出维修模式" message:@"请输入 AegisLock 独立密码。设备锁屏密码和 Face ID 在这里无效。" preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *tf){ tf.secureTextEntry=YES; tf.keyboardType=UIKeyboardTypeNumberPad; }];
    [a addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"退出" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action){
        NSString *pass=a.textFields.firstObject.text ?: @"";
        if (ALVerifyPasscode(pass)) {
            ALSetRepairMode(NO);
            notify_post(ALDisableRepairModeNotification.UTF8String);
            [self alert:@"维修模式已关闭" detail:@"所有 App 已恢复访问。建议退出 AegisRepair 后重新锁屏一次。"];
        }
        else { [self alert:@"密码错误" detail:@"维修模式保持开启。"] ; }
    }]];
    [self presentViewController:a animated:YES completion:nil];
}
- (void)alert:(NSString *)title detail:(NSString *)detail { UIAlertController *a=[UIAlertController alertControllerWithTitle:title message:detail preferredStyle:UIAlertControllerStyleAlert]; [a addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]]; [self presentViewController:a animated:YES completion:nil]; }
@end
