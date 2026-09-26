#!/bin/bash
# 让内核接受任意签名的 com.sukisu.ultra 作为管理器（KernelSU 内核侧补丁）
set -e
TARGET="$1"
if [ -z "$TARGET" ] || [ ! -d "$TARGET" ]; then
  echo "usage: $0 <kernel_platform dir>" >&2
  exit 2
fi
echo "searching under: $TARGET"
F=$(find "$TARGET" -path '*kernel/manager/apk_sign.c' 2>/dev/null | head -1)
if [ -z "$F" ]; then
  echo "apk_sign.c not found under $TARGET" >&2
  find "$TARGET" -name 'apk_sign.c' 2>/dev/null | head -5 >&2
  exit 3
fi
echo "patch target: $F"
cp -f "$F" "$F.orig"
sed -i '1i #define KSU_MANAGER_PACKAGE "com.sukisu.ultra" /* patched */' "$F"
sed -i 's|if (check_v2_signature(path, EXPECTED_SIZE, EXPECTED_HASH)) {|if (1) { /* patched: any signature */|' "$F"
echo "=== after patch ==="
head -3 "$F"
grep -n -A2 'patched: any signature' "$F" || true
echo "PATCH OK"
