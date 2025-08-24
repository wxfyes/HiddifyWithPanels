# 获取现有keystore文件的Base64编码
# 用于配置GitHub Secrets

Write-Host "=== 获取Keystore Base64编码 ===" -ForegroundColor Green

# 检查keystore文件是否存在
$keystorePath = "keys\hiddify-with-panels.keystore"
if (-not (Test-Path $keystorePath)) {
    Write-Host "错误：找不到keystore文件：$keystorePath" -ForegroundColor Red
    Write-Host "请先运行 prepare-android-keys.ps1 脚本生成keystore文件" -ForegroundColor Yellow
    exit 1
}

# 读取keystore文件并转换为Base64
try {
    Write-Host "正在读取keystore文件..." -ForegroundColor Yellow
    $keystoreBytes = [System.IO.File]::ReadAllBytes($keystorePath)
    $base64String = [System.Convert]::ToBase64String($keystoreBytes)
    
    Write-Host "✓ Base64转换完成！" -ForegroundColor Green
    Write-Host ""
    
    # 显示GitHub Secrets配置信息
    Write-Host "=== GitHub Secrets配置信息 ===" -ForegroundColor Cyan
    Write-Host "请在GitHub仓库的Settings > Secrets and variables > Actions中配置以下secrets：" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. ANDROID_KEYSTORE_BASE64" -ForegroundColor White
    Write-Host "   值：$base64String" -ForegroundColor Green
    Write-Host ""
    Write-Host "2. ANDROID_KEY_ALIAS" -ForegroundColor White
    Write-Host "   值：hiddify-with-panels" -ForegroundColor Green
    Write-Host ""
    Write-Host "3. ANDROID_KEY_PASSWORD" -ForegroundColor White
    Write-Host "   值：hiddify123" -ForegroundColor Green
    Write-Host ""
    Write-Host "4. ANDROID_STORE_PASSWORD" -ForegroundColor White
    Write-Host "   值：hiddify123" -ForegroundColor Green
    Write-Host ""
    
    # 保存Base64到文件
    $base64File = "keys\keystore-base64.txt"
    $base64String | Out-File -FilePath $base64File -Encoding UTF8
    Write-Host "✓ Base64值已保存到：$base64File" -ForegroundColor Green
    
} catch {
    Write-Host "✗ 转换失败：$($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== 完成 ===" -ForegroundColor Green
Write-Host "现在您可以配置GitHub Secrets并重新触发构建了！" -ForegroundColor Yellow
