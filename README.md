# Pixel 9 Series Supercharger v2.5

Systemless performance, maintenance, and profile management for the Pixel 9 series on Tensor G4.

## Focus

- Smooth daily responsiveness
- Safe post-boot tuning
- Clean KernelSU WebUI dashboard
- One-tap maintenance and support snapshots
- ART optimization for user apps and selected safe system apps
- Profile control for daily use and gaming sessions
- Optional synchronization with Supercharger Thermal Control
- Camera-cutout-safe WebUI spacing

## Profiles

### Active Smooth

Active Smooth is the default daily profile. It applies conservative VM, page-cluster, network, block I/O stats, and selective IRQ tuning where supported by the kernel.

### Performance / Gaming

Performance / Gaming is experimental. It is intended for gaming sessions and heavier foreground workloads.

It may apply, where supported by the kernel:

- Performance VM targets
- Lower swappiness target
- Dirty writeback adjustment
- Top-app and foreground uclamp tuning
- GPU devfreq governor set to `performance` when exposed by the kernel\n- GPU frequency floor fallback when the performance governor is unavailable
- Storage read-ahead floor of 512 KB when current value is lower
- BBR TCP congestion control when available, otherwise cubic
- Stronger IRQ affinity mask where accepted by the kernel
- Thermal Control `gaming` profile request

Reboot after switching profiles before evaluating behavior.

## Thermal Control sync

When Supercharger Thermal Control is installed, Supercharger requests the matching thermal profile:

- Active Smooth → balanced
- Performance / Gaming → gaming

If Thermal Control is pending reboot or disabled, Supercharger reports that state and queues the request.

## Safety

Active Smooth does not modify CPU clocks, GPU clocks, charging behavior, scheduler, read-ahead values, or stock thermal limits.

Performance / Gaming uses best-effort writes and safe fallback behavior. If the kernel rejects a node, the module leaves it unchanged.
