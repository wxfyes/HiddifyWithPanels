# 统一更新系统说明

## 概述

本项目已配置统一的更新系统，所有平台都使用GitHub Release页面进行版本检查和更新下载。

## 更新机制

### 1. **统一更新源**
- **所有平台**: GitHub Release页面
- **更新检查**: GitHub API
- **下载地址**: GitHub Release Assets

### 2. **支持的平台**
- ✅ **Android**: APK/AAB文件
- ✅ **Windows**: EXE/MSIX文件
- ✅ **macOS**: DMG/PKG文件
- ✅ **Linux**: AppImage/DEB/RPM文件
- ✅ **iOS**: IPA文件（开发测试）

## 配置文件

### 1. **appcast.xml** - macOS更新配置
```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
    <channel>
        <title>HiddifyWithPanels Release</title>
        <item>
            <title>Version 0.13.6</title>
            <pubDate>Sun, 7 Jan 2024 22:00:00 +0000</pubDate>
            <enclosure
                url="https://github.com/wxfyes/HiddifyWithPanels/releases/latest"
                sparkle:version="0.13.6" sparkle:os="windows" />
        </item>
        <!-- 其他平台配置 -->
    </channel>
</rss>
```

### 2. **Constants.dart** - 应用内更新配置
```dart
static const githubReleasesApiUrl = "https://api.github.com/repos/wxfyes/HiddifyWithPanels/releases";
static const githubLatestReleaseUrl = "https://github.com/wxfyes/HiddifyWithPanels/releases/latest";
static const appCastUrl = "https://raw.githubusercontent.com/wxfyes/HiddifyWithPanels/main/appcast.xml";
```

## 更新流程

### 1. **版本检查**
```
应用启动 → 检查更新 → 调用GitHub API → 获取最新版本信息
```

### 2. **版本比较**
```
当前版本 vs 最新版本 → 判断是否需要更新
```

### 3. **下载更新**
```
用户确认更新 → 获取平台特定下载链接 → 下载安装包
```

## 使用方法

### 1. **配置GitHub仓库**
在 `Constants.dart` 中已配置为你的仓库：
```dart
static const githubReleasesApiUrl = "https://api.github.com/repos/wxfyes/HiddifyWithPanels/releases";
```

### 2. **创建Release**
在GitHub上创建Release时，确保：
- 标签格式：`v1.0.0`（推荐）
- 上传对应平台的安装包
- 填写Release说明

### 3. **文件命名规范**
为了自动识别平台，建议使用以下命名规范：
- **Android**: `HiddifyWithPanels-Android-v1.0.0.apk`
- **Windows**: `HiddifyWithPanels-Windows-v1.0.0.exe`
- **macOS**: `HiddifyWithPanels-MacOS-v1.0.0.dmg`
- **Linux**: `HiddifyWithPanels-Linux-v1.0.0.AppImage`

## 技术实现

### 1. **UnifiedUpdateRepository**
统一的更新仓库，处理所有平台的更新逻辑：
```dart
@riverpod
class UnifiedUpdateRepository extends _$UnifiedUpdateRepository {
  Future<RemoteVersionEntity> _getLatestVersionFromGitHub() async {
    // 调用GitHub API获取最新Release
  }
  
  Future<String?> getPlatformDownloadUrl(String platform) async {
    // 获取特定平台的下载链接
  }
}
```

### 2. **平台检测**
自动根据文件名识别平台：
```dart
if (name.contains('Android') || name.contains('.apk')) {
  platformUrls['android'] = downloadUrl;
} else if (name.contains('Windows') || name.contains('.exe')) {
  platformUrls['windows'] = downloadUrl;
}
// ... 其他平台
```

### 3. **版本比较**
智能版本号比较：
```dart
int _compareVersions(String version1, String version2) {
  // 支持 x.y.z 格式的版本号比较
}
```

## 优势

### 1. **统一管理**
- 所有平台使用同一个更新源
- 版本管理更简单
- 发布流程更统一

### 2. **自动识别**
- 根据文件名自动识别平台
- 无需手动配置平台特定URL
- 支持新平台自动扩展

### 3. **用户友好**
- 用户可以直接访问GitHub Release页面
- 查看详细的更新说明
- 选择适合的安装包

## 注意事项

### 1. **GitHub API限制**
- 未认证用户：60次/小时
- 认证用户：5000次/小时
- 建议添加适当的缓存机制

### 2. **网络依赖**
- 需要网络连接检查更新
- 建议添加离线模式支持
- 考虑添加更新检查频率限制

### 3. **版本兼容性**
- 确保新版本向后兼容
- 提供版本迁移说明
- 考虑添加自动回滚机制

## 故障排除

### 1. **更新检查失败**
- 检查网络连接
- 验证GitHub仓库地址
- 确认Release是否公开

### 2. **平台识别错误**
- 检查文件名命名规范
- 确认文件扩展名正确
- 验证GitHub Release Assets

### 3. **下载失败**
- 检查文件是否可访问
- 验证GitHub权限设置
- 确认文件大小限制

## 未来改进

### 1. **增量更新**
- 支持增量更新包
- 减少下载时间和流量

### 2. **自动安装**
- Windows: 自动下载并安装
- macOS: 自动挂载DMG
- Linux: 自动安装包

### 3. **更新通知**
- 推送通知新版本
- 定时检查更新
- 用户偏好设置
