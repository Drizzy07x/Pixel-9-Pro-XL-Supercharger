# Pixel 9 Pro Series Supercharger 🚀
**Current Version:** v2.0 Stable (The Efficiency & Android 16 Update)

A low-level kernel optimization module built specifically for the Tensor G4 (Zumapro) architecture. This module doesn't rely on brute-force overclocking; it uses smart engineering to route hardware interrupts, manipulate UFS storage queues, and tune TCP buffers for maximum efficiency.

### 📊 Performance vs. Stock (Android 16 GKI)
In strict A/B testing using PCMark Work 3.0:
* **Zero Thermal Throttling:** Maintained a perfectly flat thermal line compared to the stock kernel's heating spikes.
* **Faster I/O:** Scored **22,098** in Writing speeds, directly beating the stock UFS configuration.

### ⚡ Core Features (v2.0)
* **Smart IRQ Engine (Android 16 Ready):** Dynamically parses `/proc/interrupts` to bypass GKI restrictions. Pins the `synaptics_tcm` (Touch) to Performance Cores for zero-latency scrolling, and isolates `ufshcd` (Storage) & `dhdpcie` (Modem) to Mid-Cores to prevent background battery drain.
* **Zero I/O Stats:** Forces storage block statistics (`iostats`) to `0`, reducing background CPU overhead.
* **5G Elasticity Buffers:** Massive dynamic read/write buffers (`tcp_rmem` / `tcp_wmem`) calibrated for 5G packet loss and cell-tower handoffs.
* **16GB RAM Profile:** Optimizes Dalvik heap sizes to take full advantage of the Pixel 9 Pro XL's massive memory pool.

### 🛠️ Installation
1. Flash in Magisk or KernelSU.
2. Reboot your device.
3. Wait 3 minutes, then check `/data/adb/modules/Pixel9_Supercharger/debug.log` to verify all engines are active and passing the audit!
4. 

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-Donate-yellow?style=for-the-badge&logo=buy-me-a-coffee)](https://www.buymeacoffee.com/Drizzy_07)
