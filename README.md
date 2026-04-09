# 🚀 Pixel 9 Pro Series Supercharger v2.3 STABLE

[![Device](https://img.shields.io/badge/Device-Pixel_9_Pro_Series-blue?logo=google&logoColor=white)](https://store.google.com/)
[![SoC](https://img.shields.io/badge/SoC-Tensor_G4-orange)](https://github.com/Drizzy07x/Supercharger_Pixel_9_Pro_Series)
[![Version](https://img.shields.io/badge/Version-v2.3_STABLE-green)](https://github.com/Drizzy07x/Supercharger_Pixel_9_Pro_Series)

**Developed by:** [Drizzy07x](https://github.com/Drizzy07x)  
**Target devices:** Pixel 9 Pro XL (`komodo`), Pixel 9 Pro (`caiman`), Pixel 9 (`comet`)  
**Channel:** Stable  
**Compatibility:** Android 16, Magisk, KernelSU

---

## ⚡ Vision
**Supercharger** is a systemless performance module designed specifically for the **Pixel 9 series** on **Tensor G4**. `v2.3 STABLE` focuses on a cleaner and more consistent daily-use profile: better balance, better audit visibility, and fewer risky or noisy tweaks.

---

## 🧠 Stable Focus

### 1. 🔍 Better Audit Visibility
- Cleaner `debug.log` structure
- More readable dashboard status
- Clear PASS / SKIP / FAIL reporting across all key areas

### 2. ⚙️ Safer Daily Tuning
- Conservative VM profile
- `vm.page-cluster=0` only when swap or zram is active
- Selective IRQ affinity instead of global routing
- Best-effort writes that skip safely on unsupported kernels

### 3. 🌡️ Low-Impact Runtime Behavior
- Dashboard temperature refresh every 5 minutes
- Description updates only when needed
- Lower log noise for expected skips

---

## 📊 Magisk Dashboard
The dashboard:

- waits for full boot
- shows profile status plus battery temperature
- refreshes temperature slowly and conditionally
- avoids unnecessary `module.prop` rewrites

This keeps the module informative without creating needless background churn.

---

## 🔍 Audit Log
All actions are written to:

`/data/adb/modules/p9pxl_supercharger/debug.log`

You can inspect it with:

```sh
su -c cat /data/adb/modules/p9pxl_supercharger/debug.log
```

---

## ⚠️ Notes
`v2.3 STABLE` is the polished daily-use profile built from the lessons of earlier beta tuning. It is intended to feel cleaner, safer, and more predictable across supported Pixel 9 Pro series devices.

---

**Supercharge your Pixel. Refine the Tensor.** 🚀

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-Donate-yellow?style=for-the-badge&logo=buy-me-a-coffee)](https://www.buymeacoffee.com/Drizzy_07)
