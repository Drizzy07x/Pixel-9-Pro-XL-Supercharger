# v2.5

## GPU / Performance Fixes

- Expanded GPU devfreq discovery beyond simple `gpu`, `mali`, and `g3d` names.
- Added detection through devfreq real paths, device metadata, and common GPU identifiers.
- Added GPU frequency policy fallback when a `performance` governor is not exposed.
- Performance / Gaming can now raise the GPU minimum frequency floor to a conservative gaming target when supported by the kernel.
- Performance / Gaming can restore the GPU maximum frequency policy to the highest available exposed value when supported by the kernel.
- Added saved GPU policy state so switching back to Active Smooth can restore previous GPU settings.
- Added GPU verification output in the deep audit.
- Added `gpu-scan` diagnostic command for unsupported kernels.

## Safety

- GPU writes remain best-effort and reversible.
- Unsupported or rejected GPU nodes are skipped safely.
- Active Smooth restores saved GPU policy where possible.
- No thermal bypass was added.
- No charging behavior was changed.
- No block scheduler override was added.
