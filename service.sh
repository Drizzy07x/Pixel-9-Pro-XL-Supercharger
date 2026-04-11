#!/system/bin/sh

MODDIR=${0%/*}
PROP_FILE="$MODDIR/module.prop"
LOG_FILE="$MODDIR/debug.log"
SNAPSHOT_FILE="$MODDIR/support_snapshot.txt"
DEVICE="$(getprop ro.product.device)"
MODEL="$(getprop ro.product.model)"
PROFILE_VERSION="v2.4-RC"

TEMP_UPDATE_INTERVAL=300
TEMP_DELTA_THRESHOLD=10

STORAGE_IRQ_PATTERNS="ufshcd|ufs"
NETWORK_IRQ_PATTERNS="wlan|wifi|wcnss|bcmdhd|dhd|rmnet|ipa"
TOUCH_IRQ_PATTERNS="synaptics|touch|goodix|fts|sec_touch|input"

ANDROID_RELEASE=""
ANDROID_SDK=""
BUILD_ID=""
BUILD_INCREMENTAL=""
KERNEL_RELEASE=""

BATTERY_TEMP_DECIC=""
BATTERY_TEMP_LABEL="Temp Unavailable"
SWAP_ACTIVE=0
PAGE_CLUSTER_STATUS="Unavailable"

SUPPORTED_CAPABILITIES=""
UNSUPPORTED_CAPABILITIES=""
SKIPPED_CAPABILITIES=""
APPLIED_CAPABILITIES=""

BLOCK_PROCESSED_COUNT=0
BLOCK_SKIPPED_COUNT=0
BLOCK_PROCESSED_LIST="none"

NETWORK_CAPABILITY_SUMMARY=""
IRQ_SUMMARY_STORAGE=""
IRQ_SUMMARY_NETWORK=""
IRQ_SUMMARY_TOUCH=""

log_line() {
    echo "$1" >> "$LOG_FILE"
}

append_csv() {
    local var_name="$1"
    local value="$2"
    local current

    current="$(eval "printf '%s' \"\${$var_name}\"")"
    if [ -z "$current" ]; then
        eval "$var_name=\"\$value\""
    else
        eval "$var_name=\"\$current, \$value\""
    fi
}

record_supported() {
    append_csv SUPPORTED_CAPABILITIES "$1"
}

record_unsupported() {
    append_csv UNSUPPORTED_CAPABILITIES "$1"
}

record_skipped() {
    append_csv SKIPPED_CAPABILITIES "$1"
}

record_applied() {
    append_csv APPLIED_CAPABILITIES "$1"
}

safe_read() {
    [ -r "$1" ] && cat "$1" 2>/dev/null
}

path_exists_and_writable() {
    [ -e "$1" ] && [ -w "$1" ]
}

safe_write_if_needed() {
    local path="$1"
    local value="$2"
    local label="$3"
    local current

    if [ ! -e "$path" ]; then
        log_line "[SKIP] $label: path unavailable ($path)"
        record_unsupported "$label"
        return 1
    fi

    if [ ! -w "$path" ]; then
        log_line "[SKIP] $label: path not writable"
        record_skipped "$label"
        return 1
    fi

    current="$(safe_read "$path")"
    if [ "$current" = "$value" ]; then
        log_line "[PASS] $label: already set to $value"
        record_supported "$label"
        return 0
    fi

    if echo "$value" > "$path" 2>/dev/null; then
        current="$(safe_read "$path")"
        if [ "$current" = "$value" ]; then
            log_line "[PASS] $label: applied $value"
            record_applied "$label"
            return 0
        fi
        log_line "[FAIL] $label: write did not persist (current=${current:-<empty>})"
        return 1
    fi

    log_line "[FAIL] $label: write rejected by kernel"
    return 1
}

verify_prop() {
    local label="$1"
    local prop="$2"
    local expected="$3"
    local current

    current="$(getprop "$prop")"
    if [ "$current" = "$expected" ]; then
        log_line "[PASS] $label: $current"
    else
        log_line "[FAIL] $label: expected $expected, got ${current:-<empty>}"
    fi
}

get_battery_temp_decic() {
    local raw

    if [ ! -r /sys/class/power_supply/battery/temp ]; then
        return 1
    fi

    raw="$(cat /sys/class/power_supply/battery/temp 2>/dev/null)"
    case "$raw" in
        ''|*[!0-9-]*)
            return 1
            ;;
        *)
            echo "$raw"
            return 0
            ;;
    esac
}

format_temp_label() {
    local decic="$1"
    local whole
    local frac

    if [ -z "$decic" ]; then
        echo "Temp Unavailable"
        return 0
    fi

    whole=$((decic / 10))
    frac=$((decic % 10))
    if [ "$frac" -lt 0 ]; then
        frac=$((frac * -1))
    fi
    echo "${whole}.${frac}C"
}

refresh_battery_temp_state() {
    BATTERY_TEMP_DECIC="$(get_battery_temp_decic)"
    BATTERY_TEMP_LABEL="$(format_temp_label "$BATTERY_TEMP_DECIC")"
}

abs_diff_decic() {
    local a="$1"
    local b="$2"
    local diff

    diff=$((a - b))
    if [ "$diff" -lt 0 ]; then
        diff=$((diff * -1))
    fi
    echo "$diff"
}

get_dashboard_status() {
    local temp_decic="$1"
    local temp_ui

    temp_ui="$(format_temp_label "$temp_decic")"
    if grep -q "FAIL" "$LOG_FILE" 2>/dev/null; then
        echo "⚠️ Status: ${PROFILE_VERSION} | ${temp_ui} | Audit Issue Detected"
    else
        echo "🚀 Status: ${PROFILE_VERSION} | ${temp_ui} | Profile Active"
    fi
}

update_dashboard() {
    local force_log="$1"
    local temp_decic="$2"
    local status
    local current_line

    status="$(get_dashboard_status "$temp_decic")"
    current_line="$(grep '^description=' "$PROP_FILE" 2>/dev/null)"

    if [ "$current_line" = "description=$status" ]; then
        if [ "$force_log" = "1" ]; then
            log_line "[PASS] Dashboard: description already up to date"
        fi
        return 0
    fi

    if sed -i "s/^description=.*/description=$status/" "$PROP_FILE" 2>/dev/null; then
        log_line "[PASS] Dashboard: description updated"
        return 0
    fi

    log_line "[FAIL] Dashboard: unable to update module.prop"
    return 1
}

start_temp_dashboard_updater() {
    (
        local last_temp_decic
        local current_temp_decic
        local delta

        last_temp_decic="$1"

        while true; do
            sleep "$TEMP_UPDATE_INTERVAL"

            current_temp_decic="$(get_battery_temp_decic)"
            if [ -z "$current_temp_decic" ]; then
                continue
            fi

            if [ -n "$last_temp_decic" ]; then
                delta="$(abs_diff_decic "$current_temp_decic" "$last_temp_decic")"
                if [ "$delta" -lt "$TEMP_DELTA_THRESHOLD" ]; then
                    continue
                fi
            fi

            if update_dashboard "0" "$current_temp_decic"; then
                last_temp_decic="$current_temp_decic"
            fi
        done
    ) &
}

wait_for_full_boot() {
    local boot_wait=0

    log_line "[INFO] ⏳ Waiting for full Android boot"
    until [ "$(getprop sys.boot_completed)" = "1" ] || [ "$boot_wait" -ge 180 ]; do
        sleep 2
        boot_wait=$((boot_wait + 2))
    done

    if [ "$(getprop sys.boot_completed)" != "1" ]; then
        log_line "[FAIL] Boot detection timed out after ${boot_wait}s"
        return 1
    fi

    boot_wait=0
    until [ "$(getprop init.svc.bootanim)" = "stopped" ] || [ "$boot_wait" -ge 60 ]; do
        sleep 2
        boot_wait=$((boot_wait + 2))
    done

    if [ "$(getprop init.svc.bootanim)" = "stopped" ]; then
        log_line "[PASS] Boot animation finished"
    else
        log_line "[SKIP] Boot animation state unavailable; continuing safely"
    fi

    sleep 10
    log_line "[PASS] System ready: post-boot grace period complete"
    return 0
}

has_active_swap() {
    local line

    if [ ! -r /proc/swaps ]; then
        return 1
    fi

    while read -r line; do
        case "$line" in
            Filename*|'')
                continue
                ;;
            *)
                return 0
                ;;
        esac
    done < /proc/swaps

    return 1
}

parse_android_version_info() {
    ANDROID_RELEASE="$(getprop ro.build.version.release)"
    ANDROID_SDK="$(getprop ro.build.version.sdk)"
    BUILD_ID="$(getprop ro.build.id)"
    BUILD_INCREMENTAL="$(getprop ro.build.version.incremental)"
    KERNEL_RELEASE="$(uname -r 2>/dev/null)"
}

get_active_scheduler() {
    local content="$1"
    echo "$content" | sed -n 's/.*\[\([^]]*\)\].*/\1/p'
}

scheduler_supports_value() {
    local content="$1"
    local desired="$2"

    case "$content" in
        *"$desired"*)
            return 0
            ;;
    esac
    return 1
}

kernel_supports_tcp_cc() {
    local desired="$1"
    local cc_available
    local current_cc

    cc_available="/proc/sys/net/ipv4/tcp_available_congestion_control"
    if [ -e "$cc_available" ]; then
        case "$(safe_read "$cc_available")" in
            *"$desired"*)
                return 0
                ;;
        esac
        return 1
    fi

    if [ -e "/proc/sys/net/ipv4/tcp_congestion_control" ]; then
        current_cc="$(safe_read /proc/sys/net/ipv4/tcp_congestion_control)"
        [ "$current_cc" = "$desired" ] && return 0
    fi

    return 1
}

set_scheduler_if_available() {
    local scheduler_path="$1"
    local desired="$2"
    local label="$3"
    local current
    local active

    if [ ! -e "$scheduler_path" ]; then
        log_line "[SKIP] $label: scheduler path unavailable"
        record_unsupported "$label"
        return 1
    fi

    if [ ! -w "$scheduler_path" ]; then
        log_line "[SKIP] $label: scheduler path not writable"
        record_skipped "$label"
        return 1
    fi

    current="$(safe_read "$scheduler_path")"
    active="$(get_active_scheduler "$current")"

    if [ "$active" = "$desired" ]; then
        log_line "[PASS] $label: already set to $desired"
        record_supported "$label"
        return 0
    fi

    if scheduler_supports_value "$current" "$desired"; then
        if echo "$desired" > "$scheduler_path" 2>/dev/null; then
            current="$(safe_read "$scheduler_path")"
            active="$(get_active_scheduler "$current")"
            if [ "$active" = "$desired" ]; then
                log_line "[PASS] $label: applied $desired"
                record_applied "$label"
                return 0
            fi
            log_line "[FAIL] $label: scheduler stayed on ${active:-unknown}"
            return 1
        fi
        log_line "[FAIL] $label: scheduler write rejected by kernel"
        return 1
    fi

    log_line "[SKIP] $label: not supported on this kernel"
    record_unsupported "$label"
    return 1
}

is_relevant_block_device() {
    local base="$1"
    local dev_path="$2"

    case "$base" in
        dm-*|loop*|ram*|zram*|md*|sr*|fd*)
            return 1
            ;;
    esac

    [ -d "$dev_path/queue" ] || return 1
    [ -e "$dev_path/device" ] || return 1

    return 0
}

log_system_version_audit() {
    parse_android_version_info

    log_line ""
    log_line "[INFO] 🧾 System Version Audit"
    log_line "[INFO] Android Release: ${ANDROID_RELEASE:-unknown}"
    log_line "[INFO] SDK Level: ${ANDROID_SDK:-unknown}"
    log_line "[INFO] Build ID: ${BUILD_ID:-unknown}"
    log_line "[INFO] Incremental Build: ${BUILD_INCREMENTAL:-unknown}"
    log_line "[INFO] Kernel Release: ${KERNEL_RELEASE:-unknown}"
    log_line "[INFO] Device Model: ${MODEL:-unknown}"
    log_line "[INFO] Device Codename: ${DEVICE:-unknown}"
}

log_compatibility_audit() {
    local page_cluster_path="/proc/sys/vm/page-cluster"
    local battery_temp_path="/sys/class/power_supply/battery/temp"
    local cc_path="/proc/sys/net/ipv4/tcp_congestion_control"
    local qdisc_path="/proc/sys/net/core/default_qdisc"
    local fastopen_path="/proc/sys/net/ipv4/tcp_fastopen"
    local dev
    local base
    local scheduler_path
    local scheduler_content
    local physical_devices="none"

    log_line ""
    log_line "[INFO] 🧩 Compatibility Audit"

    if has_active_swap; then
        SWAP_ACTIVE=1
        log_line "[PASS] Swap/ZRAM: active"
    else
        SWAP_ACTIVE=0
        log_line "[SKIP] Swap/ZRAM: not active"
    fi

    if [ -e "$page_cluster_path" ]; then
        log_line "[PASS] VM Page Cluster Path: available"
        record_supported "VM Page Cluster Path"
    else
        log_line "[SKIP] VM Page Cluster Path: unavailable"
        record_unsupported "VM Page Cluster Path"
    fi

    refresh_battery_temp_state
    if [ -r "$battery_temp_path" ] && [ -n "$BATTERY_TEMP_DECIC" ]; then
        log_line "[PASS] Battery Temp Sensor: valid (${BATTERY_TEMP_LABEL})"
        record_supported "Battery Temp Sensor"
    else
        log_line "[SKIP] Battery Temp Sensor: unavailable or invalid"
        record_unsupported "Battery Temp Sensor"
    fi

    for dev in /sys/block/*; do
        [ -d "$dev" ] || continue
        base="$(basename "$dev")"
        if ! is_relevant_block_device "$base" "$dev"; then
            continue
        fi

        if [ "$physical_devices" = "none" ]; then
            physical_devices="$base"
        else
            physical_devices="$physical_devices, $base"
        fi

        scheduler_path="$dev/queue/scheduler"
        if [ -e "$scheduler_path" ]; then
            scheduler_content="$(safe_read "$scheduler_path")"
            log_line "[INFO] Block Device ($base) Schedulers: ${scheduler_content:-unknown}"
            if scheduler_supports_value "$scheduler_content" "none"; then
                log_line "[PASS] Block Scheduler ($base): 'none' available"
            else
                log_line "[SKIP] Block Scheduler ($base): 'none' not available"
            fi
        else
            log_line "[SKIP] Block Scheduler ($base): scheduler path unavailable"
        fi
    done
    log_line "[INFO] Physical Block Devices Detected: $physical_devices"

    if [ -e "$qdisc_path" ]; then
        log_line "[PASS] Network Qdisc Path: available"
        record_supported "Network Qdisc Path"
    else
        log_line "[SKIP] Network Qdisc Path: unavailable"
        record_unsupported "Network Qdisc Path"
    fi

    if kernel_supports_tcp_cc "cubic"; then
        log_line "[PASS] TCP Congestion Control: cubic available"
        record_supported "TCP Congestion Control"
    else
        if [ -e "$cc_path" ]; then
            log_line "[SKIP] TCP Congestion Control: cubic unavailable"
        else
            log_line "[SKIP] TCP Congestion Control Path: unavailable"
        fi
        record_unsupported "TCP Congestion Control"
    fi

    if [ -e "$fastopen_path" ]; then
        log_line "[PASS] TCP Fast Open Path: available"
        record_supported "TCP Fast Open Path"
    else
        log_line "[SKIP] TCP Fast Open Path: unavailable"
        record_unsupported "TCP Fast Open Path"
    fi

    log_irq_path_capability "$STORAGE_IRQ_PATTERNS" "Storage/UFS IRQ"
    log_irq_path_capability "$NETWORK_IRQ_PATTERNS" "Wi-Fi/Network IRQ"
    log_irq_path_capability "$TOUCH_IRQ_PATTERNS" "Touch/Input IRQ"
}

log_irq_path_capability() {
    local patterns="$1"
    local label="$2"
    local found=0
    local available=0
    local irq_num

    for irq_num in $(grep -iE "$patterns" /proc/interrupts 2>/dev/null | awk -F: '{print $1}' | tr -d ' '); do
        found=$((found + 1))
        if [ -e "/proc/irq/$irq_num/smp_affinity" ]; then
            available=$((available + 1))
        fi
    done

    if [ "$found" -eq 0 ]; then
        log_line "[SKIP] $label Compatibility: no matching IRQs found"
    else
        log_line "[INFO] $label Compatibility: found $found | affinity paths $available"
    fi
}

apply_vm_tuning() {
    log_line ""
    log_line "[INFO] 🧠 Virtual Memory Audit"

    safe_write_if_needed "/proc/sys/vm/vfs_cache_pressure" "60" "VFS Cache Pressure"
    safe_write_if_needed "/proc/sys/vm/dirty_background_ratio" "5" "VM Dirty Background Ratio"
    safe_write_if_needed "/proc/sys/vm/dirty_ratio" "12" "VM Dirty Ratio"

    if has_active_swap; then
        safe_write_if_needed "/proc/sys/vm/swappiness" "30" "VM Swappiness"
    else
        log_line "[SKIP] VM Swappiness: no active swap or zram detected"
    fi
}

apply_page_cluster() {
    local current_status

    log_line ""
    log_line "[INFO] 📦 Page Cluster Audit"

    if has_active_swap; then
        safe_write_if_needed "/proc/sys/vm/page-cluster" "0" "VM Page Cluster"
        current_status="$(safe_read /proc/sys/vm/page-cluster)"
        PAGE_CLUSTER_STATUS="${current_status:-unknown}"
    else
        log_line "[SKIP] VM Page Cluster: no active swap or zram detected"
        PAGE_CLUSTER_STATUS="Skipped (no swap/zram)"
    fi
}

apply_block_tuning() {
    local dev
    local base
    local processed_devices=""

    BLOCK_PROCESSED_COUNT=0
    BLOCK_SKIPPED_COUNT=0
    BLOCK_PROCESSED_LIST="none"

    log_line ""
    log_line "[INFO] 💾 Block I/O Audit"

    for dev in /sys/block/*; do
        [ -d "$dev" ] || continue
        base="$(basename "$dev")"

        if ! is_relevant_block_device "$base" "$dev"; then
            BLOCK_SKIPPED_COUNT=$((BLOCK_SKIPPED_COUNT + 1))
            continue
        fi

        if [ -z "$processed_devices" ]; then
            processed_devices="$base"
        else
            processed_devices="$processed_devices, $base"
        fi
    done

    if [ -n "$processed_devices" ]; then
        BLOCK_PROCESSED_LIST="$processed_devices"
    fi

    log_line "[INFO] Skipped virtual/stacked block devices: $BLOCK_SKIPPED_COUNT"
    log_line "[INFO] Processing physical block devices: $BLOCK_PROCESSED_LIST"

    for dev in /sys/block/*; do
        [ -d "$dev" ] || continue
        base="$(basename "$dev")"

        if ! is_relevant_block_device "$base" "$dev"; then
            continue
        fi

        BLOCK_PROCESSED_COUNT=$((BLOCK_PROCESSED_COUNT + 1))
        log_line "[INFO] Block Device ($base): processing"
        set_scheduler_if_available "$dev/queue/scheduler" "none" "Block Scheduler ($base)"
        safe_write_if_needed "$dev/queue/read_ahead_kb" "256" "Block Read Ahead ($base)"

        if [ -e "$dev/queue/iostats" ]; then
            safe_write_if_needed "$dev/queue/iostats" "0" "Block IO Stats ($base)"
        else
            log_line "[SKIP] Block IO Stats ($base): path unavailable"
            record_unsupported "Block IO Stats ($base)"
        fi
    done

    log_line "[PASS] Block Device Scan: processed $BLOCK_PROCESSED_COUNT devices, skipped $BLOCK_SKIPPED_COUNT"
}

apply_network_tuning() {
    local cc_available
    local current_cc
    local qdisc_ok="no"
    local cubic_ok="no"
    local fastopen_ok="no"

    log_line ""
    log_line "[INFO] 🌐 Network Audit"

    if safe_write_if_needed "/proc/sys/net/core/default_qdisc" "fq" "Network Qdisc"; then
        qdisc_ok="yes"
    fi

    cc_available="/proc/sys/net/ipv4/tcp_available_congestion_control"
    if [ -e "$cc_available" ]; then
        if kernel_supports_tcp_cc "cubic"; then
            if safe_write_if_needed "/proc/sys/net/ipv4/tcp_congestion_control" "cubic" "TCP Congestion Control"; then
                cubic_ok="yes"
            fi
        else
            log_line "[SKIP] TCP Congestion Control: cubic not supported on this kernel"
            record_unsupported "TCP Congestion Control"
        fi
    elif [ -e "/proc/sys/net/ipv4/tcp_congestion_control" ]; then
        current_cc="$(safe_read /proc/sys/net/ipv4/tcp_congestion_control)"
        if [ "$current_cc" = "cubic" ]; then
            log_line "[PASS] TCP Congestion Control: already set to cubic"
            cubic_ok="yes"
            record_supported "TCP Congestion Control"
        else
            log_line "[SKIP] TCP Congestion Control: availability unknown on this kernel"
            record_skipped "TCP Congestion Control"
        fi
    else
        log_line "[SKIP] TCP Congestion Control: path unavailable"
        record_unsupported "TCP Congestion Control"
    fi

    if safe_write_if_needed "/proc/sys/net/ipv4/tcp_fastopen" "1" "TCP Fast Open"; then
        fastopen_ok="yes"
    fi

    NETWORK_CAPABILITY_SUMMARY="fq=$qdisc_ok, cubic=$cubic_ok, tcp_fastopen=$fastopen_ok"
}

set_irq_affinity_value() {
    local path="$1"
    local mask="$2"
    local label="$3"
    local current

    if [ ! -e "$path" ]; then
        log_line "[SKIP] $label: affinity path unavailable"
        return 2
    fi

    if [ ! -w "$path" ]; then
        log_line "[SKIP] $label: affinity path not writable"
        return 3
    fi

    current="$(safe_read "$path")"
    if [ "$current" = "$mask" ]; then
        log_line "[PASS] $label: already set to $mask"
        return 0
    fi

    if echo "$mask" > "$path" 2>/dev/null; then
        current="$(safe_read "$path")"
        if [ "$current" = "$mask" ]; then
            log_line "[PASS] $label: applied $mask"
            return 0
        fi
    fi

    log_line "[SKIP] $label: write rejected by kernel; keeping default routing"
    return 1
}

apply_irq_affinity() {
    local patterns="$1"
    local mask="$2"
    local label="$3"
    local found=0
    local applied=0
    local rejected=0
    local omitted=0
    local irq_num
    local rc
    local summary

    for irq_num in $(grep -iE "$patterns" /proc/interrupts 2>/dev/null | awk -F: '{print $1}' | tr -d ' '); do
        found=$((found + 1))
        set_irq_affinity_value "/proc/irq/$irq_num/smp_affinity" "$mask" "$label IRQ $irq_num"
        rc=$?
        case "$rc" in
            0) applied=$((applied + 1)) ;;
            1) rejected=$((rejected + 1)) ;;
            *) omitted=$((omitted + 1)) ;;
        esac
    done

    if [ "$found" -eq 0 ]; then
        log_line "[SKIP] $label: no matching IRQs found"
    fi

    summary="found $found | applied $applied | rejected $rejected | omitted $omitted"
    log_line "[PASS] $label Summary: $summary"

    case "$label" in
        "Storage/UFS IRQ") IRQ_SUMMARY_STORAGE="$summary" ;;
        "Wi-Fi/Network IRQ") IRQ_SUMMARY_NETWORK="$summary" ;;
        "Touch/Input IRQ") IRQ_SUMMARY_TOUCH="$summary" ;;
    esac
}

apply_selective_irq_affinity() {
    log_line ""
    log_line "[INFO] 🎯 Selective IRQ Affinity Audit"

    apply_irq_affinity "$STORAGE_IRQ_PATTERNS" "70" "Storage/UFS IRQ"
    apply_irq_affinity "$NETWORK_IRQ_PATTERNS" "70" "Wi-Fi/Network IRQ"
    apply_irq_affinity "$TOUCH_IRQ_PATTERNS" "f0" "Touch/Input IRQ"
}

write_support_snapshot() {
    {
        echo "Supercharger Support Snapshot"
        echo "Version: $PROFILE_VERSION"
        echo "Android Release: ${ANDROID_RELEASE:-unknown}"
        echo "SDK: ${ANDROID_SDK:-unknown}"
        echo "Build ID: ${BUILD_ID:-unknown}"
        echo "Incremental: ${BUILD_INCREMENTAL:-unknown}"
        echo "Kernel: ${KERNEL_RELEASE:-unknown}"
        echo "Model: ${MODEL:-unknown}"
        echo "Codename: ${DEVICE:-unknown}"
        echo "Battery Temp: ${BATTERY_TEMP_LABEL:-Temp Unavailable}"
        echo "Swap Active: ${SWAP_ACTIVE}"
        echo "Page Cluster Status: ${PAGE_CLUSTER_STATUS:-unknown}"
        echo "Processed Block Devices: ${BLOCK_PROCESSED_LIST:-none}"
        echo "Skipped Block Devices: ${BLOCK_SKIPPED_COUNT:-0}"
        echo "Network Capability Summary: ${NETWORK_CAPABILITY_SUMMARY:-unknown}"
        echo "IRQ Storage Summary: ${IRQ_SUMMARY_STORAGE:-unknown}"
        echo "IRQ Network Summary: ${IRQ_SUMMARY_NETWORK:-unknown}"
        echo "IRQ Touch Summary: ${IRQ_SUMMARY_TOUCH:-unknown}"
        echo "Supported Capabilities: ${SUPPORTED_CAPABILITIES:-none}"
        echo "Unsupported Capabilities: ${UNSUPPORTED_CAPABILITIES:-none}"
        echo "Skipped Safely: ${SKIPPED_CAPABILITIES:-none}"
        echo "Applied Successfully: ${APPLIED_CAPABILITIES:-none}"
    } > "$SNAPSHOT_FILE"
}

log_support_summary() {
    log_line ""
    log_line "[INFO] 📋 Dashboard Audit"
    log_line "[INFO] Support Snapshot: $SNAPSHOT_FILE"
    log_line "[INFO] Supported Capabilities: ${SUPPORTED_CAPABILITIES:-none}"
    log_line "[INFO] Unsupported Capabilities: ${UNSUPPORTED_CAPABILITIES:-none}"
    log_line "[INFO] Skipped Safely: ${SKIPPED_CAPABILITIES:-none}"
    log_line "[INFO] Applied Successfully: ${APPLIED_CAPABILITIES:-none}"
}

[ -f "$LOG_FILE" ] || touch "$LOG_FILE"
chmod 0644 "$LOG_FILE" 2>/dev/null

echo "===============================================" > "$LOG_FILE"
echo "   🚀 SUPERCHARGER ${PROFILE_VERSION} DEEP AUDIT" >> "$LOG_FILE"
echo "   📱 Device: $MODEL ($DEVICE)" >> "$LOG_FILE"
echo "   📅 Date: $(date)" >> "$LOG_FILE"
echo "===============================================" >> "$LOG_FILE"

log_system_version_audit

if ! wait_for_full_boot; then
    log_line ""
    log_line "[INFO] 📋 Dashboard Audit"
    update_dashboard "1" ""
    exit 0
fi

log_compatibility_audit

log_line ""
log_line "[INFO] 🌡️ Battery Status"
if [ -n "$BATTERY_TEMP_DECIC" ]; then
    log_line "[PASS] Battery Temperature: $BATTERY_TEMP_LABEL"
else
    log_line "[SKIP] Battery Temperature: sensor unavailable"
fi

log_line ""
log_line "[INFO] 🔍 System and RAM Audit"
verify_prop "Dalvik Heap Start" "dalvik.vm.heapstartsize" "32m"
verify_prop "Dalvik Heap Growth" "dalvik.vm.heapgrowthlimit" "512m"
verify_prop "Dalvik Heap Size" "dalvik.vm.heapsize" "1024m"
verify_prop "Touch Latency" "persist.sys.touch.latency" "0"

apply_vm_tuning
apply_page_cluster
apply_block_tuning
apply_network_tuning
apply_selective_irq_affinity

echo "" >> "$LOG_FILE"
echo "===============================================" >> "$LOG_FILE"
echo "   AUDIT COMPLETE - PROFILE ACTIVE" >> "$LOG_FILE"
echo "===============================================" >> "$LOG_FILE"

write_support_snapshot
log_support_summary
sleep 10
update_dashboard "1" "$BATTERY_TEMP_DECIC"
start_temp_dashboard_updater "$BATTERY_TEMP_DECIC"

exit 0
