# 🚀 Pixel 9 Pro Series Supercharger v2.2 STABLE

[![Device](https://img.shields.io/badge/Device-Pixel_9_Pro_Series-blue?logo=google&logoColor=white)](https://store.google.com/)
[![SoC](https://img.shields.io/badge/SoC-Tensor_G4-orange)](https://github.com/Drizzy07x/Pixel-9-Pro-XL-Supercharger)
[![Version](https://img.shields.io/badge/Version-v2.2_STABLE-green)](https://github.com/Drizzy07x/Pixel-9-Pro-XL-Supercharger)

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
- `dirty_ratio=20`
- `swappiness=30`
- UFS scheduler set to `none` when supported
- UFS read-ahead set to `1024` KB when supported

Every write is validated first, so unsupported kernels are skipped cleanly and reported in the audit log.

### 3. 🌐 Network Profile
The networking stack is tuned for stable burst performance:

- `default_qdisc=fq`
- `tcp_congestion_control=cubic`
- `tcp_tw_reuse=1`
- `tcp_fastopen=3`
- Larger `tcp_rmem` and `tcp_wmem` buffers

### 4. 🎮 IRQ Affinity Routing
The module rebalances IRQ affinity to reduce contention between touch, I/O, and the rest of the system:

- Generic IRQ nodes are moved to an efficiency mask where writable
- Storage and network related IRQs are pushed toward mid cores
- Touch-related IRQs are pushed toward performance cores when detected

---

## 📊 Magisk Dashboard
Supercharger updates the Magisk dashboard **once**, after Android has fully finished booting.

- It waits for `sys.boot_completed=1`
- It checks `init.svc.bootanim=stopped` when available
- It adds a post-boot grace delay before updating the dashboard
- It reads battery temperature only once for that final dashboard update
- It shows a warning if any `[FAIL]` entry appears in `debug.log`

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
4. Wait about 1 to 2 minutes after the lockscreen appears.
5. Open Magisk and confirm the dashboard status changed from boot-waiting to the final result.

---

## ⚠️ Disclaimer
This module is meant for advanced users. Even though `v2.2 STABLE` is more defensive than earlier builds, kernel behavior can still vary across ROMs and vendor configurations. Always keep a backup and test carefully after flashing.

---

**Supercharge your Pixel. Unleash the Tensor.** 🚀

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-Donate-yellow?style=for-the-badge&logo=buy-me-a-coffee)](https://www.buymeacoffee.com/Drizzy_07)
