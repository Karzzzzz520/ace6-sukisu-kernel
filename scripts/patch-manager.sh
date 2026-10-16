#!/bin/bash
# 让内核接受任意签名的 com.sukisu.ultra 作为管理器
# 自动适配上游改名：10-13 起 get_pkg_from_apk_path -> get_pkg_from_apk_dir_path
set -e
TARGET="$1"
if [ -z "$TARGET" ] || [ ! -d "$TARGET" ]; then
  echo "usage: $0 <kernel_platform dir>" >&2
  exit 2
fi
F=$(find "$TARGET" -path '*kernel/manager/apk_sign.c' 2>/dev/null | head -1)
if [ -z "$F" ]; then
  echo "apk_sign.c not found" >&2
  exit 3
fi
echo "patch target: $F"
cp -f "$F" "$F.orig"
FN="get_pkg_from_apk_path"
if grep -rqs 'get_pkg_from_apk_dir_path' "$TARGET"; then FN="get_pkg_from_apk_dir_path"; fi
echo "use function: $FN"
sed -i '1i #define KSU_MANAGER_PACKAGE "com.sukisu.ultra" /* patched */' "$F"
FN="$FN" python3 - "$F" <<'PY'
import os, sys
p = sys.argv[1]
fn = os.environ.get('FN', 'get_pkg_from_apk_path')
NL = chr(10)
s = open(p).read()
i = s.index('bool is_manager_apk(char *path)')
j = s.index(NL + '}' + NL, i) + 3
new = 'bool is_manager_apk(char *path)' + NL + '{' + NL
new += '#ifdef KSU_MANAGER_PACKAGE' + NL
new += '    char pkg[KSU_MAX_PACKAGE_NAME];' + NL
new += '    if (' + fn + '(pkg, path) < 0) {' + NL
new += '        pr_err("Failed to get package name from apk path: %s", path);' + NL
new += '        return false;' + NL
new += '    }' + NL
new += '    if (strncmp(pkg, KSU_MANAGER_PACKAGE, sizeof(KSU_MANAGER_PACKAGE))) {' + NL
new += '        return false;' + NL
new += '    }' + NL
new += '    pr_info("KernelSU: manager package matched, accept any signature");' + NL
new += '    return true;' + NL
new += '#else' + NL
new += '    return false;' + NL
new += '#endif' + NL
new += '}' + NL
open(p, 'w').write(s[:i] + new + s[j:])
print('replaced is_manager_apk using', fn)
PY
echo "=== after patch ==="
sed -n '/bool is_manager_apk/,/^}/p' "$F"
grep -q 'accept any signature' "$F" || { echo "PATCH FAILED" >&2; exit 4; }
echo "PATCH OK"
