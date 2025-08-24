# GitHub Actions 工作流说明

本项目包含两个主要的GitHub Actions工作流，用于自动构建和发布应用程序。

## 工作流文件

### 1. `auto-build.yml` - 完整发布构建

**触发条件：**
- 推送到 `main` 或 `master` 分支
- 创建版本标签（如 `v1.0.0`）
- 手动触发（可选择平台）

**功能：**
- 构建所有平台的发布版本
- 自动创建GitHub Release
- 上传构建产物到Release页面

**支持的平台：**
- ✅ Android (APK + AAB)
- ✅ Windows (Setup + Portable)
- ✅ macOS (DMG + PKG)
- ✅ Linux (AppImage + DEB + RPM)
- ✅ iOS (无签名IPA，仅用于开发测试)

### 2. `quick-build.yml` - 快速开发构建

**触发条件：**
- 推送到 `develop` 或 `dev` 分支
- Pull Request到主分支
- 手动触发（可选择平台）

**功能：**
- 快速构建用于测试
- 上传构建产物到Artifacts
- 保留7天

**支持的平台：**
- ✅ Android (Debug APK)
- ✅ Windows
- ✅ macOS
- ✅ Linux

## GitHub Secrets 配置

### 必需的 Secrets

#### `SENTRY_DSN` (推荐)
用于错误追踪：
1. 进入 GitHub 仓库 → Settings → Secrets and variables → Actions
2. 点击 "New repository secret"
3. Name: `SENTRY_DSN`
4. Value: 您的 Sentry DSN 值

### 配置步骤

1. **进入仓库设置：**
   ```
   GitHub仓库 → Settings → Secrets and variables → Actions
   ```

2. **添加 Secrets：**
   - 点击 "New repository secret"
   - 输入 Name 和 Value
   - 点击 "Add secret"

3. **验证配置：**
   - 在 Actions 页面可以看到 Secrets 被引用
   - 构建时会自动使用这些密钥

## 使用方法

### 自动触发

1. **发布版本：**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **开发构建：**
   ```bash
   git push origin develop
   ```

### 手动触发

1. 进入GitHub仓库页面
2. 点击 "Actions" 标签
3. 选择对应的工作流
4. 点击 "Run workflow"
5. 选择目标平台（可选）
6. 点击 "Run workflow"

## 构建产物

### 发布版本
构建产物会自动上传到GitHub Release页面，包括：
- Android: `HiddifyWithPanels-Android.apk` 和 `.aab`
- Windows: `HiddifyWithPanels-Windows-x64.exe` 和 `.msix`
- macOS: `HiddifyWithPanels-MacOS.dmg` 和 `.pkg`
- Linux: `HiddifyWithPanels-Linux-x64.AppImage`、`.deb`、`.rpm`
- iOS: `HiddifyWithPanels-iOS-unsigned.ipa` (无签名，仅开发测试)

### 开发版本
构建产物上传到Actions Artifacts，保留7天。

## 环境变量

工作流使用以下环境变量：
- `FLUTTER_VERSION`: Flutter版本（当前：3.24.0）
- `CHANNEL`: 构建渠道（prod/dev）
- `SENTRY_DSN`: Sentry错误追踪（需要配置）

## 注意事项

1. **iOS构建**：构建的是无签名IPA文件，仅用于开发测试，无法直接安装到设备
2. **macOS构建**：需要macOS运行器，构建时间较长
3. **依赖缓存**：Flutter依赖会自动缓存以提高构建速度
4. **构建时间**：完整构建所有平台约需30-60分钟
5. **Secrets安全**：所有Secrets都是加密存储的，不会在日志中显示

## iOS 说明

- iOS构建生成的是无签名IPA文件
- 无法直接安装到iOS设备上
- 仅用于开发测试和验证构建过程
- 如需分发到App Store，需要Apple开发者账号和代码签名

## 故障排除

### 常见问题

1. **构建失败**：
   - 检查Flutter版本兼容性
   - 验证依赖项是否正确安装
   - 查看构建日志获取详细错误信息

2. **依赖问题**：
   - 清理Flutter缓存：`flutter clean`
   - 重新获取依赖：`flutter pub get`

3. **平台特定问题**：
   - Android: 检查JDK版本（需要17）
   - Windows: 确保使用Windows运行器
   - macOS: 检查Xcode版本兼容性

4. **Secrets问题**：
   - 确保所有必需的Secrets都已配置
   - 检查Secrets名称是否正确
   - 验证Secrets值格式是否正确

### 获取帮助

如果遇到问题，请：
1. 查看Actions日志
2. 检查构建环境配置
3. 验证Secrets配置
4. 提交Issue到GitHub仓库
