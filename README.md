# AegisLock Repair Mode 0.1.0

面向越狱 iPhone 的维修/访客模式原型。目标：维修人员即使知道设备锁屏密码，也不能退出维修模式；退出只接受单独的 AegisLock 数字密码。

## 当前功能

- 维修模式独立 4–12 位数字密码（与设备密码、Face ID 无关）
- 密码使用随机 salt + SHA-256 保存，不明文保存
- 维修模式下默认仅允许 `AegisRepair`
- 可手工追加允许访问的 App Bundle ID
- 被禁止的 UIKit App 激活后立即显示隐私遮罩并挂起
- AegisRepair 内置“退出维修模式”，只接受独立密码，因此即使“设置”被锁也能安全退出
- 附带 AegisRepair：
  - Face ID / Touch ID 生物识别测试
  - 前后摄像头测试
  - 震动/触觉测试
  - 扬声器提示音测试
  - RGB/白/黑屏幕测试
  - 触摸轨迹测试

## 为什么默认不允许“设置”

维修人员如果知道设备密码，完整放行“设置”会暴露 Apple ID、账户、通知、VPN、密码相关入口等。AegisRepair 使用 `LocalAuthentication` 单独测试 Face ID，因此不需要开放“设置”。

## 构建：Dopamine Rootless

需要 Theos 与 iOS SDK：

```bash
make clean
make package THEOS_PACKAGE_SCHEME=rootless FINALPACKAGE=1
```

Theos 的 rootless scheme 会处理 `/var/jb` 前缀；iOS 15+ 可只编译 arm64/arm64e。

## 构建：RootHide

使用 RootHide 官方 Theos：

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/roothide/theos/master/bin/install-theos)"
make clean
make package THEOS_PACKAGE_SCHEME=roothide FINALPACKAGE=1
```

RootHide 官方文档说明其 Theos 支持从使用 rootless 路径宏的现有 tweak 项目构建 roothide 包。

## 安装后

1. 打开 设置 → AegisLock。
2. 先设置“维修模式独立密码”。不要与设备锁屏密码相同。
3. 确认 AegisRepair 可以正常启动。
4. 开启维修模式。
5. 测试：尝试打开微信/相册/文件等，应出现遮罩并立即回到后台。
6. 维修完成后直接打开 AegisRepair → “退出维修模式”，输入独立密码退出。无需开放“设置”。

## 已知限制 / 下一步

这是 0.1.0 原型，不是苹果硬件级安全边界：

- 有 Root/SSH/终端能力的人可修改 preference 文件、卸载 tweak 或进入安全模式绕过。
- 目前主要保护“打开 App”；尚未完整屏蔽 Spotlight 搜索结果、Siri、通知中心内容、App Switcher 历史快照和 USB/SSH。
- 当前全局 App 拦截依赖 MobileSubstrate 的 UIKit 注入策略，不同 bootstrap 需要真机验证。
- 建议 0.2 加：SpringBoard 级启动前拦截、通知隐藏、切换器快照清理、控制中心快捷开关、密码错误限速。

## 安全提醒

维修前仍建议：备份数据、关闭 SSH 或修改默认 SSH 密码、避免给维修人员 Root/终端入口。
