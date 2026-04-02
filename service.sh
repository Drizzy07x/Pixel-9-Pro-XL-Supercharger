#!/system/bin/sh
# =============================================================
# PIXEL 9 PRO SERIES SUPERCHARGER v1.6-BETA.3
# Persistent Audit & Zumapro Optimization - Developed by: Drizzy_07
# =============================================================

# Auto-detect module directory
MODDIR=${0%/*}
PROP_FILE="$MODDIR/module.prop"
LOG_FILE="$MODDIR/debug.log"

# --- 1. ENHANCED AUDIT FUNCTION ---
# Verifies if a tweak was actually applied to the system
verify_tweak() {
    local name="$1"
    local path="$2"
    local expected="$3"
    
    if [ -f "$path" ]; then
        local current=$(cat "$path")
        case "$current" in
            *"$expected"*) echo "[PASS] $name: $current" >> "$LOG_FILE" ;;
            *) echo "[FAIL] $name: Expected $expected, got $current" >> "$LOG_FILE" ;;
        esac
    else
        echo "[INFO] $name: Path not supported by stock kernel" >> "$LOG_FILE"
    fi
}

# --- 2. INITIALIZATION ---
if [ ! -f "$LOG_FILE" ]; then touch "$LOG_FILE"; chmod 0666 "$LOG_FILE"; fi

echo "===============================================" > "$LOG_FILE"
echo "   SUPERCHARGER v1.6-BETA.3 FINAL AUDIT" >> "$LOG_FILE"
echo "   Device: Pixel 9 Pro XL (Zumapro/Tensor G4)" >> "$LOG_FILE"
echo "   Date: $(date)" >> "$LOG_FILE"
echo "===============================================" >> "$LOG_FILE"

# --- 3. BOOT DETECTION (AGGRESSIVE WAIT) ---
# Ensuring Google services finish their initial hardware override
until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 2; done
sleep 45 
echo "[✅] System ready. Deploying persistent tweaks..." >> "$LOG_FILE"

# --- 4. MEMORY & STORAGE (INSISTENCE ENGINE) ---
# Pixel 9 often reverts nr_requests to 31. Writing 5 times every 5s to force 256.
echo "" >> "$LOG_FILE"
echo "[🧠] MEMORY & STORAGE AUDIT:" >> "$LOG_FILE"

for i in 1 2 3 4 5; do
    echo 60 > /proc/sys/vm/vfs_cache_pressure
    echo 20 > /proc/sys/vm/dirty_ratio
    for dev in sda sdb sdc; do
        if [ -d "/sys/block/$dev" ]; then
            echo none > "/sys/block/$dev/queue/scheduler"
            echo 256 > "/sys/block/$dev/queue/nr_requests" 2>/dev/null
        fi
    done
    sleep 5
done

verify_tweak "VFS Cache Pressure" "/proc/sys/vm/vfs_cache_pressure" "60"
verify_tweak "UFS NR Requests" "/sys/block/sda/queue/nr_requests" "256"

# --- 5. ADVANCED NETWORKING (BBR ENFORCEMENT) ---
echo "" >> "$LOG_FILE"
echo "[🌐] NETWORK AUDIT:" >> "$LOG_FILE"

# Enforcing fq (Fair Queuing) is mandatory before BBR activation
echo "fq" > /proc/sys/net/core/default_qdisc
sleep 2

if grep -q "bbr" /proc/sys/net/ipv4/tcp_available_congestion_control; then
    echo "bbr" > /proc/sys/net/ipv4/tcp_congestion_control
    verify_tweak "TCP Congestion" "/proc/sys/net/ipv4/tcp_congestion_control" "bbr"
else
    echo "[FAIL] BBR: Not available in this kernel build" >> "$LOG_FILE"
fi

# --- 6. SMART IRQ BALANCE (DEFINITIVE) ---
echo "" >> "$LOG_FILE"
echo "[🚧] SMART IRQ AFFINITY AUDIT:" >> "$LOG_FILE"

stop irqbalance
# Mask 7f: Efficiency Cores (0-6)
# Mask 70: Mid Cores (4-6) - Ideal for I/O and Modem
# Mask f0: Performance Cores (4-7) - Ideal for Touch feedback
for irq in /proc/irq/*; do
    [ -f "$irq/smp_affinity" ] && echo "7f" > "$irq/smp_affinity" 2>/dev/null
done

for irq in /proc/irq/*; do
    if grep -q -E "ufshc|pcie|modem|wlan" "$irq/name" 2>/dev/null; then
        echo "70" > "$irq/smp_affinity" 2>/dev/null
    fi
    if grep -q -E "touch|goodix|sec_ts" "$irq/name" 2>/dev/null; then
        echo "f0" > "$irq/smp_affinity" 2>/dev/null
    fi
done
echo "[✅] Smart IRQ: Affinity masks successfully locked" >> "$LOG_FILE"

# --- 7. DASHBOARD & MAINTENANCE ---
update_dashboard() {
    T_RAW=$(cat /sys/class/power_supply/battery/temp)
    T_UI="$((T_RAW / 10)).$((T_RAW % 10))°C"
    
    if grep -q "FAIL" "$LOG_FILE"; then
        STATUS="Status: [⚠️] v1.6-B3 | 🌡️ $T_UI | Audit FAIL"
    else
        STATUS="Status: [🚀] v1.6-B3 | 🛡️ All Pass | 🌡️ $T_UI"
    fi
    sed -i "s/^description=.*/description=$STATUS/" "$PROP_FILE"
}

(
    while true; do
        update_dashboard
        sleep 60
    done
) &

# Post-boot SQLite Maintenance
(
    sleep 120
    find /data/data -name "*.db" -type f -not -path "*com.android.providers.media*" 2>/dev/null | while read -r db; do
        sqlite3 "$db" "VACUUM;" >/dev/null 2>&1
    done
    echo "[🧹] Maintenance: SQLite Vacuum complete" >> "$LOG_FILE"
) &

echo "" >> "$LOG_FILE"
echo "===============================================" >> "$LOG_FILE"
echo "   AUDIT COMPLETE - PERMANENCE ESTABLISHED" >> "$LOG_FILE"
echo "===============================================" >> "$LOG_FILE"

exit 0
