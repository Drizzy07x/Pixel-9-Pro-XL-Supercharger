# 🚀 Pixel 9 Pro Series Supercharger v2.2 STABLE

[![Device](https://img.shields.io/badge/Device-Pixel_9_Pro_Series-blue?logo=google&logoColor=white)](https://store.google.com/)
[![SoC](https://img.shields.io/badge/SoC-Tensor_G4-orange)](https://github.com/Drizzy07x/Supercharger_Pixel_9_Pro_Series)
[![Version](https://img.shields.io/badge/Version-v2.2_STABLE-green)](https://github.com/Drizzy07x/Supercharger_Pixel_9_Pro_Series)

**Developed by:** [Drizzy07x](https://github.com/Drizzy07x)  
**Target devices:** Pixel 9 Pro XL (`komodo`), Pixel 9 Pro (`caiman`), Pixel 9 (`comet`)  
**Compatibility:** Android 16, Magisk, KernelSU

---

## ⚡ Vision
**Supercharger** is a systemless performance module designed specifically for the **Pixel 9 series** on **Tensor G4**. Instead of relying only on late shell tweaks, it combines early property injection with post-boot hardware tuning so the device can feel faster, smoother, and more responsive without modifying `/system`.

---

## 🧠 Power Engines

### 1. 🧬 Early-Boot VM Profile
`system.prop` injects ART and touch-related properties early in the boot sequence.

- `dalvik.vm.heapstartsize=32m`
- `dalvik.vm.heapgrowthlimit=512m`
- `dalvik.vm.heapsize=1024m`
- `persist.sys.touch.latency=0`

This keeps the memory profile stable from the start and avoids the instability that can happen when changing Dalvik values too late.

### 2. 💾 Smart Storage Tuning
The module applies conservative virtual-memory and storage tuning after boot:

- `vfs_cache_pressure=60`
- `dirty_background_ratio=5`
- `dirty_ratio=12`
- `swappiness=30` only when swap or zram is active
- Dynamic block-device detection
- `read_ahead_kb=256` when supported

Every write is validated first, so unsupported kernels are skipped cleanly and reported in the audit log.

### 3. 🌐 Network Profile
The networking stack is tuned for stable burst performance:

- `default_qdisc=fq` when supported
- `tcp_congestion_control=cubic` only when available
- `tcp_fastopen=1` when supported

Aggressive overrides were removed to keep the profile cleaner and safer for daily use.

### 4. 🎮 Selective IRQ Affinity
IRQ tuning is now selective instead of global:

- Storage-related IRQs are tuned only when matching real kernel entries
- Network-related IRQs are tuned only when matching real kernel entries
- Touch-related IRQs are tuned only when matching real kernel entries
- High battery temperature triggers a thermal guard that skips heavier I/O and IRQ tuning

---

## 📊 Magisk Dashboard
Supercharger updates the Magisk dashboard **once**, after Android has fully finished booting.

- It waits for `sys.boot_completed=1`
- It checks `init.svc.bootanim=stopped` when available
- It adds a short post-boot grace delay before updating the dashboard
- It reads battery temperature only once for the final dashboard update
- It shows a warning if any `[FAIL]` entry appears in `debug.log`
- It avoids rewriting `module.prop` when the description is already correct

This keeps the dashboard informative without running a permanent loop that wastes battery.

---

## 🔍 Audit Log
All actions are written to:

`/data/adb/modules/p9pxl_supercharger/debug.log`

You can inspect it with:

```sh
su -c cat /data/adb/modules/p9pxl_supercharger/debug.log
```

---

## ⚙️ Installation
1. Download `Supercharger-v2.2.zip`.
2. Flash it from **Magisk** or **KernelSU**.
3. Reboot the device.
4. Wait a short moment after the lockscreen appears.
5. Open Magisk and confirm the dashboard status changed from boot-waiting to the final result.

---

## ⚠️ Disclaimer
This module is meant for advanced users. `v2.2 STABLE` is tuned to be more defensive and device-aware than earlier builds, but kernel behavior can still vary across ROMs and vendor configurations. Always keep a backup and test carefully after flashing.

---

**Supercharge your Pixel. Unleash the Tensor.** 🚀

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-Donate-yellow?style=for-the-badge&logo=buy-me-a-coffee)](https://www.buymeacoffee.com/Drizzy_07)
