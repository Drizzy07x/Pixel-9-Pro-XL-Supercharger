# 📑 Changelog - Pixel 9 Pro XL Supercharger

All notable changes to the **Supercharger** project will be documented in this file.

---

## [v2.1 STABLE] - 2026-04-04
### 🚀 Major Architecture Overhaul
* **Migrated Memory Tweaks to `system.prop`:** Moved `dalvik.vm` heap configurations from late-stage shell injection (`service.sh`) to early-boot injection. This prevents the **SIGABRT (Signal 6) Zygote64** crashes caused by hot-swapping VM parameters on Android 16.
* **Stable 16GB RAM Profile:** Successfully implemented a 1024MB Max Heap size, allowing the Pixel 9 Pro XL to fully utilize its physical memory without UI stutter or background app kills.

### 🛠️ Refinements & Fixes
* **Vulkan Renderer Removal:** Deprecated the forced `skiavk` (Vulkan) injection. Reverting to the native crDroid OpenGL/SkiaGL backend resolved the "Reliable surface detection" errors and fixed UI jank.
* **Smart IRQ Balancing v2:** Optimized interrupt masks specifically for the **Tensor G4 (Zumapro)**. 
    * Touch Panel (`synaptics_tcm`) now has exclusive access to Prime Cores.
    * Network and UFS interrupts isolated to Mid Cores to maintain thermal efficiency.
* **TCP Stack Stabilization:** Locked congestion control to `cubic` to ensure 100% compatibility with Stock and Custom kernels while maintaining high-burst network buffers (16MB).
* **Enhanced Audit Engine:** Added "Read-Only" property verification in `service.sh` to monitor the success of `system.prop` injections without interfering with the system server.

### 🧹 Cleanup
* Removed experimental LMKD (Low Memory Killer) tweaks that caused system instability on Android 16 QPR2.
* Consolidated UFS 4.0 block optimizations across `sda`, `sdb`, and `sdc` nodes.

---

## [v2.0] - 2026-03-31
### ✨ Initial Tensor G4 Release
* **Introduction of Smart IRQ Balance:** First implementation of manual interrupt affinity for Pixel 9 series.
* **UFS 4.0 Supercharging:** Initial implementation of `none` scheduler and `read_ahead` optimizations.
* **Smart Network Engine:** Deployment of `fq` qdisc and increased TCP window sizes.
* **Maintenance Automation:** Added background SQLite vacuuming and reindexing for app database health.

---

> **Reflecting on v2.1:** This update marks the move from "Experimental" to "Production-Ready." By understanding the boot-sequence of Android 16, we've achieved maximum performance without compromising the integrity of the system framework.
> 
