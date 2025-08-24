# 验证keystore密码并重新生成
# 用于解决签名密码问题

Write-Host "=== 验证和重新生成Keystore ===" -ForegroundColor Green

# 设置密钥参数
$keystorePath = "keys\hiddify-with-panels.keystore"
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

# 如果keystore文件存在，先尝试验证密码
if (Test-Path $keystorePath) {
    Write-Host "正在验证现有keystore的密码..." -ForegroundColor Yellow
    try {
        # 尝试列出keystore内容来验证密码
        $keytoolArgs = @(
            "-list", "-v",
            "-keystore", $keystorePath,
            "-storepass", $storePassword
        )
        
        $result = & $keytoolPath @keytoolArgs 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ 现有keystore密码验证成功" -ForegroundColor Green
            Write-Host "keystore信息：" -ForegroundColor Cyan
            $result | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
        } else {
            Write-Host "✗ 现有keystore密码验证失败，将重新生成" -ForegroundColor Yellow
            Remove-Item $keystorePath -Force
        }
    } catch {
        Write-Host "✗ 验证现有keystore时出错，将重新生成" -ForegroundColor Yellow
        Remove-Item $keystorePath -Force
    }
}

# 如果keystore不存在或密码错误，重新生成
if (-not (Test-Path $keystorePath)) {
    Write-Host "正在生成新的keystore文件..." -ForegroundColor Yellow
    
    # 确保keys目录存在
    $keysDir = Split-Path $keystorePath -Parent
    if (-not (Test-Path $keysDir)) {
        New-Item -ItemType Directory -Path $keysDir | Out-Null
    }
    
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
            Write-Host "✓ 新keystore文件生成成功" -ForegroundColor Green
        } else {
            Write-Host "✗ keystore文件生成失败" -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "✗ 生成keystore时出错：$($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# 转换为Base64
Write-Host "正在转换为Base64格式..." -ForegroundColor Yellow
try {
    $keystoreBytes = [System.IO.File]::ReadAllBytes($keystorePath)
    $base64String = [System.Convert]::ToBase64String($keystoreBytes)
    
    # 保存Base64到文件
    $base64File = "keys\keystore-base64.txt"
    $base64String | Out-File -FilePath $base64File -Encoding UTF8
    Write-Host "✓ Base64转换完成，保存到：$base64File" -ForegroundColor Green
    
    # 显示前100个字符（用于验证）
    Write-Host "Base64前100个字符：$($base64String.Substring(0, [Math]::Min(100, $base64String.Length)))..." -ForegroundColor Cyan
    
} catch {
    Write-Host "✗ Base64转换失败：$($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

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
Write-Host "现在请更新GitHub Secrets并重新触发构建！" -ForegroundColor Yellow
