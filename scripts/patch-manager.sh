#!/bin/bash
# 让内核接受任意签名的 com.sukisu.ultra 作为管理器（KernelSU 内核侧补丁）
set -e
TARGET="${1:-kernel_workspace/kernel_platform}"
F=$(find "$TARGET" -path '*kernel/manager/apk_sign.c' | head -1)
echo "patch target: $F"
test -n "$F"
cp -f "$F" "$F.orig"
# 1) 强制定义管理器包名，让包名校验生效
sed -i '1i #define KSU_MANAGER_PACKAGE "com.sukisu.ultra" /* patched */' "$F"
# 2) 跳过 v2 签名校验
sed -i 's|if (check_v2_signature(path, EXPECTED_SIZE, EXPECTED_HASH)) {|if (1) { /* patched: any signature */|' "$F"
echo "=== after patch ==="
head -3 "$F"
grep -n -A2 'patched: any signature' "$F"
echo "OK"
