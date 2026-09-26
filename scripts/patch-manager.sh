#!/bin/bash
# 让内核接受任意签名的 com.sukisu.ultra 作为管理器
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
sed -i '1i #define KSU_MANAGER_PACKAGE "com.sukisu.ultra" /* patched */' "$F"
python3 - "$F" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
i = s.index('bool is_manager_apk(char *path)')
j = s.index('\n}\n', i) + 3
new = '''bool is_manager_apk(char *path)
{
#ifdef KSU_MANAGER_PACKAGE
    char pkg[KSU_MAX_PACKAGE_NAME];
    if (get_pkg_from_apk_path(pkg, path) < 0) {
        pr_err("Failed to get package name from apk path: %s\\n", path);
        return false;
    }
    if (strncmp(pkg, KSU_MANAGER_PACKAGE, sizeof(KSU_MANAGER_PACKAGE))) {
        return false;
    }
    pr_info("KernelSU: manager package matched, accept any signature\\n");
    return true;
#else
    return false;
#endif
}
'''
open(p, 'w').write(s[:i] + new + s[j:])
print('replaced is_manager_apk')
PY
echo "=== after patch ==="
sed -n '/bool is_manager_apk/,/^}/p' "$F"
grep -q 'accept any signature' "$F" || { echo "PATCH FAILED" >&2; exit 4; }
echo "PATCH OK"
