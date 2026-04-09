# 📝 Changelog - Pixel 9 Pro Series Supercharger

All notable changes to **Supercharger** are documented here.

---

## [v2.3 STABLE] - 2026-04-09

This stable release keeps the profile conservative, readable, and well-audited.  
The goal of `v2.3 STABLE` is to retain the tweaks that provide the best balance between smoothness, battery life, thermal consistency, and boot safety on the **Pixel 9 Pro XL / Pixel 9 Pro series**.

### Highlights
- Removed unnecessary runtime variation
- Kept only the most stable and consistent tuning paths
- Improved presentation of both Magisk dashboard and audit logs
- Maintained best-effort behavior across unsupported kernels
- Focused on daily-use stability over aggressive tweaking

### Changes
- Kept `vm.page-cluster=0` only when swap or zram is active
- Kept selective IRQ affinity only for storage/UFS, Wi-Fi/network, and touch/input
- Removed `cpu.uclamp.latency_sensitive` writes from the service profile
- Preserved conservative VM tuning with clear per-setting logging
- Preserved block I/O tuning with per-device logging and summary output
- Preserved safe network tuning with cleaner audit wording
- Refined dashboard wording and visual presentation
- Refined `debug.log` section headers and message consistency
- Kept battery temperature refresh slow and conditional to reduce overhead

### Focus of this release
- Better daily stability
- Better readability and diagnostics
- Lower battery impact
- Cleaner boot behavior
- More polished stable presentation

### Notes
This release is intended to be the clean and dependable profile for everyday use.  
It does not try to be harsher than previous builds; instead, it aims to be more predictable, more transparent, and easier to trust.

---

## [v2.2 STABLE] - 2026-04-08

This release focuses on refining the module instead of adding more aggressive tweaks.  
The goal of v2.2 is to deliver a cleaner, safer, and more device-aware tuning profile for daily use on the **Pixel 9 Pro XL / Pixel 9 Pro series**.

### Highlights
- Removed overly aggressive global IRQ behavior
- Switched to more selective and safer tuning logic
- Improved thermal awareness to protect stability and battery life
- Reduced unnecessary boot-time writes
- Kept the module focused on real-world smoothness instead of excessive tweaking

### Changes
- Removed global IRQ affinity application across all IRQ nodes
- Moved toward selective IRQ handling for relevant hardware only
- Reworked block I/O tuning to detect valid block devices dynamically
- Reduced `read_ahead_kb` defaults for a more balanced storage profile
- Added safer scheduler validation before applying block scheduler changes
- Improved VM tuning with more conservative dirty memory behavior
- Applied `swappiness` only when swap/zram is actually active
- Cleaned up network tuning by removing unnecessary aggressive overrides
- Added thermal guard logic to skip heavier tweaks when battery temperature is high
- Reduced redundant writes during boot by making settings conditional
- Kept Dalvik/ART checks as audit-only for safer daily operation
- Improved dashboard update behavior to avoid unnecessary `module.prop` rewrites

---

## [v2.1 STABLE] - 2026-04-04
### 🚀 Major Architecture Overhaul
- Moved `dalvik.vm` heap configuration from late shell injection in `service.sh` into `system.prop` for early injection.
- Stabilized the 16 GB RAM profile with a `1024m` max heap target.

### 🛠️ Refinements and Fixes
- Removed the forced Vulkan renderer tweak to avoid UI issues on Android 16.
- Improved IRQ balancing for Tensor G4.
- Locked network congestion control to `cubic` for broad compatibility.
- Added read-only verification for injected properties.

### 🧹 Cleanup
- Removed unstable LMKD experiments.
- Consolidated UFS tuning logic across `sda`, `sdb`, and `sdc`.
