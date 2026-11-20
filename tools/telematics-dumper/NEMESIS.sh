#!/system/bin/sh
# HKMC Telematics / Bluelink Diagnostic Dumper
# NEMESIS Run-Script: Runs as root, cwd = USB root

export PATH=/sbin:/vendor/bin:/system/sbin:/system/bin:/system/xbin:$PATH
export LD_LIBRARY_PATH=/vendor/lib:/system/lib

TIMESTAMP=$(date +%Y%m%d_%H%M%S 2>/dev/null)
if [ -z "$TIMESTAMP" ]; then
    TIMESTAMP="latest"
fi

OUT="telematics_dump_${TIMESTAMP}.txt"
LOGCAT_OUT="telematics_logcat_${TIMESTAMP}.txt"

echo "==========================================================" > "$OUT"
echo " HKMC Telematics & Unactivated Bluelink Popup Diagnostic Dump" >> "$OUT"
echo " Timestamp: $(date 2>/dev/null || echo 'Unknown')" >> "$OUT"
echo " Uptime: $(uptime 2>/dev/null)" >> "$OUT"
echo "==========================================================" >> "$OUT"

echo "" >> "$OUT"
echo "--- [1. DEVICE INFO] ---" >> "$OUT"
echo "Product: $(getprop ro.build.product 2>/dev/null)" >> "$OUT"
echo "TargetDir: $(getprop ro.mobis.targetdir 2>/dev/null)" >> "$OUT"
echo "Display ID: $(getprop ro.build.display.id 2>/dev/null)" >> "$OUT"
echo "Fingerprint: $(getprop ro.build.fingerprint 2>/dev/null)" >> "$OUT"
echo "Boot Completed: $(getprop sys.boot_completed 2>/dev/null)" >> "$OUT"

echo "" >> "$OUT"
echo "--- [2. CURRENT TOP WINDOW & FOCUS] ---" >> "$OUT"
dumpsys window windows 2>/dev/null | grep -E "mCurrentFocus|mFocusedApp|mFocus|Window #" >> "$OUT"

echo "" >> "$OUT"
echo "--- [3. TOP ACTIVITY & ACTIVITY STACK] ---" >> "$OUT"
dumpsys activity top 2>/dev/null >> "$OUT"

echo "" >> "$OUT"
echo "--- [4. ALL RUNNING ACTIVITIES (FILTERED)] ---" >> "$OUT"
dumpsys activity activities 2>/dev/null | grep -E "Stack #|TaskRecord|Hist #" >> "$OUT"

echo "" >> "$OUT"
echo "--- [5. ACTIVE NOTIFICATIONS] ---" >> "$OUT"
dumpsys notification 2>/dev/null | grep -E "NotificationRecord|pkg=|tag=|id=" >> "$OUT"

echo "" >> "$OUT"
echo "--- [6. TELEMATICS & HKMC PACKAGES INSTALLED] ---" >> "$OUT"
pm list packages -f 2>/dev/null | grep -iE "telematics|tmu|bluelink|uvo|modem|setting|hkmc" >> "$OUT"

echo "" >> "$OUT"
echo "--- [7. RELEVANT RUNNING PROCESSES (PS)] ---" >> "$OUT"
ps 2>/dev/null | grep -iE "telematics|tmu|bluelink|uvo|modem|hkmc|factory" >> "$OUT"

echo "" >> "$OUT"
echo "--- [8. BINDER SERVICES (SERVICE LIST)] ---" >> "$OUT"
service list 2>/dev/null | grep -iE "telematics|tmu|bluelink|uvo|modem|factory|phone" >> "$OUT"

echo "" >> "$OUT"
echo "--- [9. TELEMATICS & MODEM SYSTEM PROPERTIES] ---" >> "$OUT"
getprop 2>/dev/null | grep -iE "telematics|tmu|modem|bluelink|uvo|gsm|ril|carrier" >> "$OUT"

echo "" >> "$OUT"
echo "--- [10. TELEMATICS APP DATA & DATABASE LISTINGS] ---" >> "$OUT"
ls -laR /data/data/*telematics* 2>/dev/null >> "$OUT"
ls -laR /data/data/*tmu* 2>/dev/null >> "$OUT"
ls -laR /data/data/*bluelink* 2>/dev/null >> "$OUT"
ls -laR /data/data/*uvo* 2>/dev/null >> "$OUT"

echo "" >> "$OUT"
echo "--- [11. FULL WINDOW DUMP (DETAILED)] ---" >> "$OUT"
dumpsys window windows 2>/dev/null >> "$OUT"

# 12. Logcat extraction (saved in separate file to keep main dump readable)
echo "[*] Extracting recent logcat..."
logcat -d -v time -t 4000 2>/dev/null > "$LOGCAT_OUT"

sync

echo "[+] Telematics dump completed successfully at $(date 2>/dev/null)."
exit 0
