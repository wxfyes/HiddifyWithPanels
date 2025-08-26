# MSIX 构建和上传配置说明

## 概述

本项目已配置完整的MSIX构建和上传流程，解决之前"找不到GitHub Release"的错误。

## 工作流文件

### 1. `auto-build.yml` - 主要构建流程
- **Windows构建**: 使用 `flutter_distributor` 自动生成MSIX包
- **MSIX构建**: 在Windows构建过程中自动生成
- **文件上传**: 将MSIX文件上传到构建产物

### 2. `msix-upload.yml` - MSIX专用上传流程
- **触发条件**: GitHub Release发布时自动运行
- **功能**: 将MSIX包上传到Microsoft Store和GitHub Release
- **错误处理**: 包含重试机制和自动Release创建

### 3. `add_signed_microsft.yml` - 原有MSIX上传流程（已优化）
- **功能**: 定期检查和上传MSIX到Microsoft Store
- **改进**: 添加了自动Release创建功能

## 关键改进

### 1. 自动Release创建
```yaml
- name: Create GitHub Release if not exists
  if: steps.check-release.outputs.exists == 'false'
  run: |
    gh release create "$VERSION" \
      --title "Release $VERSION_NUMBER" \
      --notes "Automatically created release for version $VERSION_NUMBER" \
      --repo ${{ github.repository }}
```

### 2. 版本号自动检测
```yaml
- name: Get latest version from Microsoft Store
  id: get-version
  run: |
    echo "version=$(cat pubspec.yaml | grep '^version:' | sed 's/version: //' | tr -d ' ')" >> $GITHUB_OUTPUT
    echo "tag_version=v$(cat pubspec.yaml | grep '^version:' | sed 's/version: //' | tr -d ' ')" >> $GITHUB_OUTPUT
```

### 3. 错误处理和重试
```yaml
with:
  create-release-if-not-exists: true
  version-prefix: "v"
  retry-count: 3
  retry-delay: 10
```

## 构建流程

1. **代码提交** → 触发 `auto-build.yml`
2. **Windows构建** → 使用 `flutter_distributor` 生成MSIX
3. **Release创建** → 创建GitHub Release（如果不存在）
4. **MSIX上传** → 上传到Microsoft Store和GitHub Release

## 使用方法

### 自动触发
- 推送到 `main` 分支
- 创建版本标签（如 `v1.0.0`）

### 手动触发
- 在GitHub Actions页面手动运行工作流
- 选择目标平台

## 故障排除

### 常见问题

1. **MSIX构建失败**
   - 检查 `flutter_distributor` 配置
   - 验证Windows构建环境

2. **上传失败**
   - 检查GitHub Token权限
   - 验证Microsoft Store ID

3. **Release创建失败**
   - 确保版本号格式正确
   - 检查仓库权限设置

### 调试步骤

1. 查看工作流日志
2. 检查构建产物
3. 验证MSIX文件生成
4. 确认Release状态

## 配置要求

### GitHub Secrets
- `GITHUB_TOKEN`: 自动提供
- `GH_TOKEN`: 用于Release创建（可选）

### 环境要求
- Windows构建环境
- Flutter 3.24.0+
- `flutter_distributor` 工具

## 注意事项

1. **版本号管理**: 确保 `pubspec.yaml` 中的版本号与GitHub Release一致
2. **权限设置**: 工作流需要 `contents: write` 权限
3. **文件路径**: MSIX文件路径配置在 `package_windows.ps1` 中
4. **重试机制**: 上传失败时会自动重试3次

## 更新日志

- **2024-01-XX**: 添加自动Release创建功能
- **2024-01-XX**: 优化MSIX构建流程
- **2024-01-XX**: 添加错误处理和重试机制
