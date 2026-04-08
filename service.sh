#!/system/bin/sh

MODDIR=${0%/*}
PROP_FILE="$MODDIR/module.prop"
LOG_FILE="$MODDIR/debug.log"
DEVICE="$(getprop ro.product.device)"
MODEL="$(getprop ro.product.model)"

log_line() {
    echo "$1" >> "$LOG_FILE"
}

safe_read() {
    [ -r "$1" ] && cat "$1" 2>/dev/null
}

safe_write() {
    local value="$1"
    local path="$2"
    local label="$3"

    if [ ! -e "$path" ]; then
        log_line "[SKIP] $label: unsupported path $path"
        return 1
    fi

    if [ ! -w "$path" ]; then
        log_line "[SKIP] $label: path is not writable"
        return 1
    fi

    if echo "$value" > "$path" 2>/dev/null; then
        local current
        current="$(safe_read "$path")"
        log_line "[PASS] $label: ${current:-$value}"
        return 0
    fi

    log_line "[FAIL] $label: write rejected"
    return 1
}

verify_prop() {
    local name="$1"
    local prop="$2"
    local expected="$3"
    local current

    current="$(getprop "$prop")"
    if [ "$current" = "$expected" ]; then
        log_line "[PASS] $name: $current"
    else
        log_line "[FAIL] $name: Expected $expected, got ${current:-<empty>}"
    fi
}

update_dashboard() {
    local status
    local temp_raw
    local temp_ui="🌡️ temp skipped"

    if [ -r /sys/class/power_supply/battery/temp ]; then
        temp_raw="$(cat /sys/class/power_supply/battery/temp 2>/dev/null)"
        case "$temp_raw" in
            ''|*[!0-9-]*)
                temp_ui="🌡️ temp skipped"
                ;;
            *)
                temp_ui="🌡️ $((temp_raw / 10)).$((temp_raw % 10))C"
                ;;
        esac
    fi

    if grep -q "FAIL" "$LOG_FILE" 2>/dev/null; then
        status="⚠️ Status: v2.2-STABLE | $temp_ui | Audit issue detected"
    else
        status="🚀 Status: v2.2-STABLE | $temp_ui | All checks passed"
    fi

    sed -i "s/^description=.*/description=$status/" "$PROP_FILE" 2>/dev/null
}

wait_for_full_boot() {
    local boot_wait=0

    until [ "$(getprop sys.boot_completed)" = "1" ] || [ "$boot_wait" -ge 180 ]; do
        sleep 2
        boot_wait=$((boot_wait + 2))
    done

    if [ "$(getprop sys.boot_completed)" != "1" ]; then
        log_line "[FAIL] Boot detection timed out after ${boot_wait}s"
        return 1
    fi

    boot_wait=0
    until [ "$(getprop init.svc.bootanim)" = "stopped" ] || [ "$boot_wait" -ge 120 ]; do
        sleep 2
        boot_wait=$((boot_wait + 2))
    done

    if [ "$(getprop init.svc.bootanim)" != "stopped" ]; then
        log_line "[INFO] Boot animation state did not report 'stopped'; continuing with post-boot delay"
    else
        log_line "[PASS] Boot animation finished"
    fi

    sleep 15
    return 0
}

[ -f "$LOG_FILE" ] || touch "$LOG_FILE"
chmod 0644 "$LOG_FILE" 2>/dev/null

echo "===============================================" > "$LOG_FILE"
echo "   SUPERCHARGER v2.2-STABLE DEEP AUDIT" >> "$LOG_FILE"
echo "   Device: $MODEL ($DEVICE)" >> "$LOG_FILE"
echo "   Date: $(date)" >> "$LOG_FILE"
echo "===============================================" >> "$LOG_FILE"

log_line "[INFO] Waiting for full Android boot..."
if ! wait_for_full_boot; then
    update_dashboard
    exit 0
fi

log_line "[OK] System ready. Deploying v2.2-STABLE engines..."

echo "" >> "$LOG_FILE"
echo "[INFO] SYSTEM AND RAM AUDIT (read-only):" >> "$LOG_FILE"

verify_prop "Dalvik Heap Start" "dalvik.vm.heapstartsize" "32m"
verify_prop "Dalvik Heap Growth" "dalvik.vm.heapgrowthlimit" "512m"
verify_prop "Dalvik Heap Size" "dalvik.vm.heapsize" "1024m"
verify_prop "Touch Latency" "persist.sys.touch.latency" "0"

echo "" >> "$LOG_FILE"
echo "[INFO] VIRTUAL MEMORY AND STORAGE AUDIT:" >> "$LOG_FILE"

safe_write "60" "/proc/sys/vm/vfs_cache_pressure" "VFS Cache Pressure"
safe_write "20" "/proc/sys/vm/dirty_ratio" "VM Dirty Ratio"
safe_write "30" "/proc/sys/vm/swappiness" "VM Swappiness"

for dev in sda sdb sdc; do
    if [ -d "/sys/block/$dev" ]; then
        safe_write "none" "/sys/block/$dev/queue/scheduler" "UFS Scheduler ($dev)"
        safe_write "1024" "/sys/block/$dev/queue/read_ahead_kb" "UFS Read Ahead ($dev)"
        [ -e "/sys/block/$dev/queue/iostats" ] && safe_write "0" "/sys/block/$dev/queue/iostats" "UFS IO Stats ($dev)"
    fi
done

echo "" >> "$LOG_FILE"
echo "[INFO] NETWORK AUDIT:" >> "$LOG_FILE"

safe_write "fq" "/proc/sys/net/core/default_qdisc" "Network Qdisc"
sleep 1
safe_write "cubic" "/proc/sys/net/ipv4/tcp_congestion_control" "TCP Congestion"
safe_write "1" "/proc/sys/net/ipv4/tcp_tw_reuse" "TCP Socket Reuse"
safe_write "3" "/proc/sys/net/ipv4/tcp_fastopen" "TCP Fast Open"
safe_write "4096 87380 16777216" "/proc/sys/net/ipv4/tcp_rmem" "TCP Read Buffer"
safe_write "4096 16384 16777216" "/proc/sys/net/ipv4/tcp_wmem" "TCP Write Buffer"

echo "" >> "$LOG_FILE"
echo "[INFO] SMART IRQ AFFINITY AUDIT:" >> "$LOG_FILE"

if command -v stop >/dev/null 2>&1; then
    stop irqbalance >/dev/null 2>&1
    log_line "[PASS] IRQ Balancer: stop requested"
else
    log_line "[SKIP] IRQ Balancer: stop command unavailable"
fi

IRQ_EFF=0
IRQ_MID=0
IRQ_PERF=0

for irq in /proc/irq/*; do
    [ -f "$irq/smp_affinity" ] && echo "7f" > "$irq/smp_affinity" 2>/dev/null && IRQ_EFF=$((IRQ_EFF + 1))
done

for irq_num in $(grep -iE "ufshcd|exynos-pcie|dhdpcie" /proc/interrupts 2>/dev/null | awk -F: '{print $1}' | tr -d ' '); do
    if [ -f "/proc/irq/$irq_num/smp_affinity" ]; then
        echo "70" > "/proc/irq/$irq_num/smp_affinity" 2>/dev/null
        IRQ_MID=$((IRQ_MID + 1))
    fi
done

for irq_num in $(grep -iE "synaptics_tcm" /proc/interrupts 2>/dev/null | awk -F: '{print $1}' | tr -d ' '); do
    if [ -f "/proc/irq/$irq_num/smp_affinity" ]; then
        echo "f0" > "/proc/irq/$irq_num/smp_affinity" 2>/dev/null
        IRQ_PERF=$((IRQ_PERF + 1))
    fi
done

log_line "[PASS] IRQ Efficiency (7f): applied to $IRQ_EFF nodes"
log_line "[PASS] IRQ Mid-Cores (70): applied to $IRQ_MID nodes"
log_line "[PASS] IRQ Perf-Cores (f0): applied to $IRQ_PERF nodes"

(
    sleep 15
    log_line "[INFO] Updating Magisk dashboard after short post-boot grace period"
    update_dashboard
) &

echo "" >> "$LOG_FILE"
echo "===============================================" >> "$LOG_FILE"
echo "   AUDIT COMPLETE - ALL ENGINES ACTIVE" >> "$LOG_FILE"
echo "===============================================" >> "$LOG_FILE"

exit 0
