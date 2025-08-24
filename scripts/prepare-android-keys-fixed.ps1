# Android签名密钥生成和Base64转换脚本
# 用于GitHub Actions的Android应用签名

Write-Host "=== Android签名密钥生成脚本 ===" -ForegroundColor Green

# 检查是否在正确的目录
if (-not (Test-Path "android")) {
    Write-Host "错误：请在项目根目录运行此脚本" -ForegroundColor Red
    exit 1
}

# 创建keys目录
$keysDir = "keys"
if (-not (Test-Path $keysDir)) {
    New-Item -ItemType Directory -Path $keysDir | Out-Null
    Write-Host "创建keys目录" -ForegroundColor Yellow
}

# 设置密钥参数
$keystorePath = "$keysDir\hiddify-with-panels.keystore"
$keyAlias = "hiddify-with-panels"
$keyPassword = "hiddify123"
$storePassword = "hiddify123"
$keytoolPath = "keytool"

# 检查keytool是否可用
try {
    $null = Get-Command $keytoolPath -ErrorAction Stop
    Write-Host "✓ keytool工具可用" -ForegroundColor Green
} catch {
    Write-Host "✗ 错误：找不到keytool工具，请确保已安装Java JDK" -ForegroundColor Red
    exit 1
}

# 生成keystore
Write-Host "正在生成keystore文件..." -ForegroundColor Yellow
$keytoolArgs = @(
    "-genkey", "-v",
    "-keystore", $keystorePath,
    "-alias", $keyAlias,
    "-keyalg", "RSA",
    "-keysize", "2048",
    "-validity", "10000",
    "-storepass", $storePassword,
    "-keypass", $keyPassword,
    "-dname", "CN=Hiddify, OU=Development, O=Hiddify, L=City, S=State, C=CN"
)

try {
    & $keytoolPath @keytoolArgs
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ keystore文件生成成功" -ForegroundColor Green
    } else {
        Write-Host "✗ keystore文件生成失败" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ 生成keystore时出错：$($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 转换为Base64
Write-Host "正在转换为Base64格式..." -ForegroundColor Yellow
try {
    $keystoreBytes = [System.IO.File]::ReadAllBytes($keystorePath)
    $base64String = [System.Convert]::ToBase64String($keystoreBytes)
    
    # 保存Base64到文件
    $base64File = "$keysDir\keystore-base64.txt"
    $base64String | Out-File -FilePath $base64File -Encoding UTF8
    Write-Host "✓ Base64转换完成，保存到：$base64File" -ForegroundColor Green
    
    # 显示前100个字符（用于验证）
    Write-Host "Base64前100个字符：$($base64String.Substring(0, [Math]::Min(100, $base64String.Length)))..." -ForegroundColor Cyan
    
} catch {
    Write-Host "✗ Base64转换失败：$($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 创建key.properties文件
Write-Host "正在创建key.properties文件..." -ForegroundColor Yellow
$keyPropertiesContent = @"
storePassword=$storePassword
keyPassword=$keyPassword
keyAlias=$keyAlias
storeFile=../keys/hiddify-with-panels.keystore
"@

$keyPropertiesPath = "android\key.properties"
$keyPropertiesContent | Out-File -FilePath $keyPropertiesPath -Encoding UTF8
Write-Host "✓ key.properties文件创建成功：$keyPropertiesPath" -ForegroundColor Green

# 显示GitHub Secrets配置信息
Write-Host "`n=== GitHub Secrets配置信息 ===" -ForegroundColor Green
Write-Host "请在GitHub仓库的Settings > Secrets and variables > Actions中配置以下secrets：" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. ANDROID_KEYSTORE_BASE64" -ForegroundColor Cyan
Write-Host "   值：$base64String" -ForegroundColor White
Write-Host ""
Write-Host "2. ANDROID_KEY_ALIAS" -ForegroundColor Cyan
Write-Host "   值：$keyAlias" -ForegroundColor White
Write-Host ""
Write-Host "3. ANDROID_KEY_PASSWORD" -ForegroundColor Cyan
Write-Host "   值：$keyPassword" -ForegroundColor White
Write-Host ""
Write-Host "4. ANDROID_STORE_PASSWORD" -ForegroundColor Cyan
Write-Host "   值：$storePassword" -ForegroundColor White
Write-Host ""

Write-Host "=== 完成 ===" -ForegroundColor Green
Write-Host "现在您可以推送代码到GitHub并触发自动构建了！" -ForegroundColor Yellow
