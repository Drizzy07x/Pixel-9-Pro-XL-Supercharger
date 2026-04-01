#!/system/bin/sh
# =============================================================
# PIXEL 9 PRO SERIES SUPERCHARGER v1.5.1 [STABLE]
# Log Generation Fix - Developed by: Drizzy_07
# =============================================================

# Auto-detect module directory (Fixes issues between Magisk, KSU, and APatch)
MODDIR=${0%/*}
PROP_FILE="$MODDIR/module.prop"
LOG_FILE="$MODDIR/debug.log"

# Define hardware variables
DEVICE=$(getprop ro.product.device)
MODEL=$(getprop ro.product.model)

# --- 1. LOG INITIALIZATION & PERMISSION ENFORCEMENT ---
# Ensure the file exists and has correct permissions before writing
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
    chmod 0666 "$LOG_FILE"
fi

# Plain text header to prevent encoding errors
echo "SUPERCHARGER DIAGNOSTIC LOG" > "$LOG_FILE"
echo "Build: v1.5.1 Stable" >> "$LOG_FILE"
echo "Device: $MODEL ($DEVICE)" >> "$LOG_FILE"
echo "Path: $MODDIR" >> "$LOG_FILE"
echo "-----------------------------------------------" >> "$LOG_FILE"

# --- 2. BOOT DETECTION ---
sed -i "s/^description=.*/description=Status: [⏳] Supercharger is waiting for system boot.../" "$PROP_FILE"
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 2
done
sleep 10
echo "[✅] System boot confirmed at $(date)" >> "$LOG_FILE"

# --- 3. PERFORMANCE TUNING (16GB RAM & UFS 4.0) ---
sed -i "s/^description=.*/description=Status: [🧠] Optimizing 16GB RAM & [⚡] UFS 4.0.../" "$PROP_FILE"

resetprop dalvik.vm.heapstartsize 32m
resetprop dalvik.vm.heapgrowthlimit 512m
resetprop dalvik.vm.heapsize 1g
echo 60 > /proc/sys/vm/vfs_cache_pressure
echo 20 > /proc/sys/vm/dirty_ratio
echo 30 > /proc/sys/vm/swappiness
echo "[🧠] RAM: 16GB Efficiency profile applied" >> "$LOG_FILE"

for queue in /sys/block/sd*/queue; do
    echo none > "$queue/scheduler"
    echo 256 > "$queue/nr_requests"
    echo 1024 > "$queue/read_ahead_kb"
done
echo "[⚡] Storage: UFS 4.0 high-throughput enabled" >> "$LOG_FILE"

# --- 4. NETWORKING & CPU FIX ---
sed -i "s/^description=.*/description=Status: [🌐] Tuning TCP/5G & [🎮] UI Fluidity.../" "$PROP_FILE"

echo 3 > /proc/sys/net/ipv4/tcp_fastopen
echo 1 > /proc/sys/net/ipv4/tcp_low_latency
echo "[🌐] Network: TCP Fast Open and Low Latency active" >> "$LOG_FILE"

echo 1 > /sys/devices/system/cpu/cpufreq/policy0/powersave_bias
echo 0 > /sys/devices/system/cpu/cpufreq/policy4/powersave_bias
echo 0 > /sys/devices/system/cpu/cpufreq/policy7/powersave_bias
echo "[🔥] CPU: Scaling fix applied to performance clusters" >> "$LOG_FILE"

# Graphics
resetprop debug.hwui.renderer skiavk
resetprop persist.sys.touch.latency 0
resetprop persist.sys.ui.hw 1

# --- 5. DYNAMIC DASHBOARD ENGINE ---
update_dashboard() {
    T_RAW=$(cat /sys/class/power_supply/battery/temp)
    T_LOG="$((T_RAW / 10)).$((T_RAW % 10))C"
    T_UI="$((T_RAW / 10)).$((T_RAW % 10))°C"
    STATUS="Status: [🚀] v1.5.1 ACTIVE | 🧠 16GB | ⚡ UFS 4.0 | 🌡️ Temp: $T_UI | ✅ Stable"
    sed -i "s/^description=.*/description=$STATUS/" "$PROP_FILE"
}

(
    while true; do
        update_dashboard
        sleep 60
    done
) &

# --- 6. ASYNC MAINTENANCE ---
(
    sleep 180
    if command -v sqlite3 >/dev/null 2>&1; then
        find /data/data -name "*.db" -type f -not -path "*com.android.providers.media*" 2>/dev/null | while read -r db; do
            sqlite3 "$db" "VACUUM; REINDEX;" >/dev/null 2>&1
        done
    fi
    cmd package bg-dexopt-job
) &

echo "[🚀] Supercharger engine fully deployed" >> "$LOG_FILE"
exit 0
