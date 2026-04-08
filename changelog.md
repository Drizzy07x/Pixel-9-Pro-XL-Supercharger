# 📝 Changelog - Pixel 9 Pro Series Supercharger

All notable changes to **Supercharger** are documented here.

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

### Focus of this release
- Better daily stability
- Better thermal consistency
- Lower risk of battery drain
- Cleaner boot behavior
- More reliable device-aware tuning

### Notes
This update is designed to make the module smarter, not harsher.  
Instead of stacking more tweaks, v2.2 improves how and when tuning is applied, with a stronger focus on efficiency, safety, and consistency for everyday use.

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

---

## [v2.0] - 2026-03-31
### ✨ Initial Tensor G4 Release
- Introduced manual IRQ affinity tuning for the Pixel 9 series.
- Added first-pass UFS scheduler and read-ahead tuning.
- Added network tuning with `fq` and larger TCP buffers.
- Introduced the deep audit log workflow.
