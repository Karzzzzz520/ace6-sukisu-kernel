# Ace 6 SukiSU+SusFS Kernel

Independent GitHub Actions workflow to build a SukiSU Ultra + SusFS kernel for OnePlus Ace 6 (sm8750, OOS16).

## Source
- Kernel: OnePlusOSS/android_kernel_oneplus_sm8750 (branch: oneplus/sm8750_b_16.0.0_ace_6)
- SukiSU: SukiSU-Ultra/SukiSU-Ultra (official setup.sh susfs-main)
- SusFS: simonpunk/susfs4ksu (gki-android15-6.6)

## Build
Go to Actions tab → Run workflow. ~30-40 min.

## Flash
```
fastboot flash init_boot ace6-sukisu-susfs-kernel.zip
```

## Backup first
```
adb shell su -c 'dd if=/dev/block/by-name/init_boot_b of=/sdcard/init_boot_backup.img'
```
