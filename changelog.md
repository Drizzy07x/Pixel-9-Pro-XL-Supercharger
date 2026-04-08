# 📝 Changelog - Pixel 9 Pro Series Supercharger

All notable changes to **Supercharger** are documented here.

---

## [v2.2 STABLE] - 2026-04-08
### 🚀 Dashboard and Boot Intelligence
- Added full-boot detection before post-boot tuning proceeds.
- Dashboard update now happens only once after boot settles.
- Magisk description now reflects final success or warning state based on `debug.log`.
- Battery temperature is sampled only once for the final dashboard update to avoid needless background activity.

### 🛡️ Stability and Safety
- Added guarded write logic for `/proc` and `/sys` nodes so unsupported paths are skipped cleanly.
- Improved post-boot flow with logging around boot completion and boot animation state.
- Removed the permanent dashboard refresh loop to reduce battery impact.
- Kept the module focused on tuning and auditing instead of long-lived maintenance work.

### 🎨 UX and Repo Cleanup
- Updated module presentation to `v2.2 STABLE`.
- Restored the installer ASCII banner while keeping emoji-based status messaging.
- Cleaned repository text encoding and refreshed project docs for UTF-8 consistency.

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
