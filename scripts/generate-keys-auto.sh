#!/bin/bash

# 自动生成Android签名密钥脚本

echo "=== HiddifyWithPanels 自动签名密钥生成脚本 ==="
echo ""

# 创建密钥目录
mkdir -p keys
cd keys

echo "1. 生成 Android 签名密钥..."

# 使用默认值
store_password="hiddify123456"
key_password="hiddify123456"
key_alias="hiddify-with-panels"

echo "使用默认配置："
echo "密钥库密码: $store_password"
echo "密钥密码: $key_password"
echo "密钥别名: $key_alias"
echo ""

# 生成Android keystore
keytool -genkey -v \
    -keystore hiddify-with-panels.keystore \
    -alias "$key_alias" \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -storepass "$store_password" \
    -keypass "$key_password" \
    -dname "CN=HiddifyWithPanels, OU=Development, O=Hiddify, L=City, S=State, C=CN"

echo "✅ Android keystore 生成完成: keys/hiddify-with-panels.keystore"

# 转换为Base64
echo "正在转换为Base64..."
base64 -i hiddify-with-panels.keystore > hiddify-with-panels.keystore.base64

echo ""
echo "=== GitHub Secrets 配置信息 ==="
echo ""
echo "请将以下内容添加到GitHub Secrets:"
echo ""
echo "ANDROID_KEYSTORE_BASE64:"
cat hiddify-with-panels.keystore.base64
echo ""
echo "ANDROID_KEY_ALIAS: $key_alias"
echo "ANDROID_KEY_PASSWORD: $key_password"
echo "ANDROID_STORE_PASSWORD: $store_password"
echo ""

echo "=== 密钥文件信息 ==="
echo "keystore文件: keys/hiddify-with-panels.keystore"
echo "Base64文件: keys/hiddify-with-panels.keystore.base64"
echo ""

echo "⚠️  重要提醒："
echo "1. 请妥善保管密钥文件和密码"
echo "2. 不要将密钥文件提交到Git仓库"
echo "3. 将Base64内容添加到GitHub Secrets"
echo "4. 密钥文件用于发布版本，请备份到安全位置"
echo ""

echo "✅ 密钥生成完成！"
