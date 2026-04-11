# 📝 Changelog - Pixel 9 Pro Series Supercharger

All notable changes to **Supercharger** are documented here.

---

## [v2.4 STABLE] - 2026-04-11

This stable release focuses on strengthening compatibility, diagnostics, and cross-version resilience while preserving the current performance profile.  
The goal of `v2.4 STABLE` is to keep the module feeling reliable and well-balanced on **Android 16 QPR3** while improving adaptability and observability for **Android 17**, without introducing harsher tuning.

### Highlights
- Improved compatibility handling across Android 16 QPR3 and Android 17
- Added stronger capability detection instead of relying on rigid version-specific behavior
- Expanded diagnostics and auditing for easier support and troubleshooting
- Preserved the current stable tuning profile without adding aggressive new tweaks
- Focused on long-term maintainability and cleaner fallback behavior

### Changes
- Added a dedicated **System Version Audit** block for Android release, SDK, build, kernel, and device reporting
- Added a **Compatibility Audit** block to validate available paths, supported options, and kernel-exposed capabilities
- Improved block I/O compatibility checks with safer scheduler parsing and stricter validation
- Improved network capability validation before applying supported values
- Improved compatibility handling for unsupported or unavailable nodes by using safer `SKIP` behavior
- Preserved `vm.page-cluster=0` only when swap or zram is active
- Preserved selective IRQ affinity for storage/UFS, Wi-Fi/network, and touch/input
- Preserved conservative VM, block I/O, and network tuning with cleaner diagnostics
- Added a more useful support-oriented audit flow for easier comparison between builds

### Focus of this release
- Better cross-version compatibility
- Better diagnostics and support visibility
- Cleaner fallback behavior
- More maintainable daily-use profile
- Stable performance without unnecessary expansion of tuning scope

### Notes
This release does not aim to push performance further through additional tweaks.  
Instead, it improves how the module detects, validates, and applies its existing profile so it can remain safer, cleaner, and more dependable across future Android updates.

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
