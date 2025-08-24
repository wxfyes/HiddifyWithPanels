# PowerShell 自动生成Android签名密钥脚本

Write-Host "=== HiddifyWithPanels 自动签名密钥生成脚本 ===" -ForegroundColor Green
Write-Host ""

# 创建密钥目录
if (!(Test-Path "keys")) {
    New-Item -ItemType Directory -Path "keys"
}
Set-Location "keys"

Write-Host "1. 生成 Android 签名密钥..." -ForegroundColor Yellow

# 使用默认值
$store_password = "hiddify123456"
$key_password = "hiddify123456"
$key_alias = "hiddify-with-panels"

Write-Host "使用默认配置：" -ForegroundColor Cyan
Write-Host "密钥库密码: $store_password"
Write-Host "密钥密码: $key_password"
Write-Host "密钥别名: $key_alias"
Write-Host ""

# 检查keytool是否可用
try {
    $keytool = Get-Command keytool -ErrorAction Stop
    Write-Host "找到keytool: $($keytool.Source)" -ForegroundColor Green
} catch {
    Write-Host "错误: 找不到keytool命令，请确保已安装Java JDK" -ForegroundColor Red
    exit 1
}

# 生成Android keystore
$keytoolArgs = @(
    "-genkey",
    "-v",
    "-keystore", "hiddify-with-panels.keystore",
    "-alias", $key_alias,
    "-keyalg", "RSA",
    "-keysize", "2048",
    "-validity", "10000",
    "-storepass", $store_password,
    "-keypass", $key_password,
    "-dname", "CN=HiddifyWithPanels, OU=Development, O=Hiddify, L=City, S=State, C=CN"
)

Write-Host "正在生成keystore..." -ForegroundColor Yellow
& keytool @keytoolArgs

if (Test-Path "hiddify-with-panels.keystore") {
    Write-Host "✅ Android keystore 生成完成: keys/hiddify-with-panels.keystore" -ForegroundColor Green
} else {
    Write-Host "❌ keystore生成失败" -ForegroundColor Red
    exit 1
}

# 转换为Base64
Write-Host "正在转换为Base64..." -ForegroundColor Yellow
$keystoreBytes = Get-Content "hiddify-with-panels.keystore" -Encoding Byte
$base64String = [Convert]::ToBase64String($keystoreBytes)
$base64String | Out-File "hiddify-with-panels.keystore.base64" -Encoding ASCII

Write-Host ""
Write-Host "=== GitHub Secrets 配置信息 ===" -ForegroundColor Green
Write-Host ""
Write-Host "请将以下内容添加到GitHub Secrets:" -ForegroundColor Yellow
Write-Host ""
Write-Host "ANDROID_KEYSTORE_BASE64:" -ForegroundColor Cyan
Write-Host $base64String
Write-Host ""
Write-Host "ANDROID_KEY_ALIAS: $key_alias" -ForegroundColor Cyan
Write-Host "ANDROID_KEY_PASSWORD: $key_password" -ForegroundColor Cyan
Write-Host "ANDROID_STORE_PASSWORD: $store_password" -ForegroundColor Cyan
Write-Host ""

Write-Host "=== 密钥文件信息 ===" -ForegroundColor Green
Write-Host "keystore文件: keys/hiddify-with-panels.keystore" -ForegroundColor Cyan
Write-Host "Base64文件: keys/hiddify-with-panels.keystore.base64" -ForegroundColor Cyan
Write-Host ""

Write-Host "⚠️  重要提醒：" -ForegroundColor Yellow
Write-Host "1. 请妥善保管密钥文件和密码" -ForegroundColor White
Write-Host "2. 不要将密钥文件提交到Git仓库" -ForegroundColor White
Write-Host "3. 将Base64内容添加到GitHub Secrets" -ForegroundColor White
Write-Host "4. 密钥文件用于发布版本，请备份到安全位置" -ForegroundColor White
Write-Host ""

Write-Host "✅ 密钥生成完成！" -ForegroundColor Green
