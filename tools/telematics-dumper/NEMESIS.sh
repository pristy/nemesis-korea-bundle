#!/system/bin/sh
# HKMC Telematics / Bluelink Diagnostic Dumper & Hardened APK Extractor
# Target: AOSP 4.4 KitKat (mksh + Toolbox) & Higher AOSP (ART/Toybox)
# NEMESIS Run-Script: Runs as root, cwd = USB root

export PATH=/system/xbin:/sbin:/vendor/bin:/system/sbin:/system/bin:$PATH
export LD_LIBRARY_PATH=/vendor/lib:/system/lib

# [안전장치 1 & 2] 40초 워치독 타이머 (포그라운드 자식 프로세스 데드락 강제 회수 & 고아 방지)
MAIN_PID=$$
(
    read -r MY_REAL_PID rest < /proc/self/stat 2>/dev/null
    SLEEP_PID=""
    trap 'if [ -n "$SLEEP_PID" ]; then kill -9 "$SLEEP_PID" 2>/dev/null; wait "$SLEEP_PID" 2>/dev/null; fi; exit 0' TERM INT
    sleep 40 &
    SLEEP_PID=$!
    wait "$SLEEP_PID" 2>/dev/null

    # 4.4 Toolbox 호환: 메인 쉘이 포그라운드 명령 대기 중 블로킹되는 현상 방지 (/proc 파싱으로 자식만 회수)
    pkill -9 -P "$MAIN_PID" 2>/dev/null || true
    for f in /proc/[0-9]*/stat; do
        [ -f "$f" ] || continue
        read -r c_pid comm state c_ppid rest < "$f" 2>/dev/null
        if [ "$c_ppid" = "$MAIN_PID" ] && [ "$c_pid" != "$MY_REAL_PID" ]; then
            kill -9 "$c_pid" 2>/dev/null || true
        fi
    done
    kill -TERM "$MAIN_PID" 2>/dev/null
) &
WATCHDOG_PID=$!

WIN_TMP=""
cleanup() {
    trap - EXIT INT TERM
    kill -TERM "$WATCHDOG_PID" 2>/dev/null || true
    wait "$WATCHDOG_PID" 2>/dev/null || true
    [ -n "$WIN_TMP" ] && rm -f "$WIN_TMP" 2>/dev/null || true
    sync
}
trap cleanup EXIT
trap 'exit 143' TERM
trap 'exit 130' INT

# --- [AOSP 4.4 환경 기능 자동 감지] ---
HAS_GREP_E=0
if echo "TestA" | grep -iE "testa|testb" >/dev/null 2>&1; then
    HAS_GREP_E=1
fi

HAS_CP=0
if type cp >/dev/null 2>&1 || command -v cp >/dev/null 2>&1; then
    HAS_CP=1
fi

HAS_LS_R=0
if ls -laR /dev/null >/dev/null 2>&1; then
    HAS_LS_R=1
fi

# --- [순수 mksh 호환 헬퍼 함수] ---
# 대소문자 무시 다중 키워드 필터 (grep -iE 없을 시 mksh 내장 기능으로 폴백)
filter_icase() {
    if [ "$HAS_GREP_E" -eq 1 ]; then
        grep -iE "$1" 2>/dev/null
        return
    fi
    typeset -l low kw_low
    old_ifs="$IFS"
    IFS='|'
    set -f
    set -- $1
    set +f
    IFS="$old_ifs"
    while IFS= read -r line || [ -n "$line" ]; do
        low="$line"
        for kw in "$@"; do
            kw_low="$kw"
            case "$low" in
                *"$kw_low"*)
                    printf '%s\n' "$line"
                    break
                    ;;
            esac
        done
    done
}

# 대소문자 구분 다중 키워드 필터 (grep -E 없을 시 mksh 내장 기능으로 폴백)
filter_exact() {
    if [ "$HAS_GREP_E" -eq 1 ]; then
        grep -E "$1" 2>/dev/null
        return
    fi
    old_ifs="$IFS"
    IFS='|'
    set -f
    set -- $1
    set +f
    IFS="$old_ifs"
    while IFS= read -r line || [ -n "$line" ]; do
        for kw in "$@"; do
            case "$line" in
                *"$kw"*)
                    printf '%s\n' "$line"
                    break
                    ;;
            esac
        done
    done
}

# 안전 파일 복사 (4.4 Toolbox에 cp가 없는 경우 cat 리다이렉션 사용, 대상은 반드시 파일 경로)
safe_cp() {
    if [ "$HAS_CP" -eq 1 ]; then
        cp "$1" "$2" 2>/dev/null
    else
        cat "$1" > "$2" 2>/dev/null
    fi
}

# /data/data 하위 목록 조회 (ls -R 미지원 4.4 Toolbox 폴백 포함)
list_data_dirs() {
    for d in "$@"; do
        if [ -d "$d" ]; then
            if [ "$HAS_LS_R" -eq 1 ]; then
                ls -laR "$d" 2>/dev/null
            else
                echo "$d:"
                ls -la "$d" 2>/dev/null
                for sub in "$d"/*; do
                    if [ -d "$sub" ]; then
                        echo "$sub:"
                        ls -la "$sub" 2>/dev/null
                    fi
                done
            fi
        fi
    done
}

# FAT32 안전한 타임스탬프 검증
TIMESTAMP=$(date +%Y%m%d_%H%M%S 2>/dev/null)
case "$TIMESTAMP" in
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9][0-9][0-9]) ;;
    *) TIMESTAMP="latest" ;;
esac

OUT="telematics_dump_${TIMESTAMP}.txt"
LOGCAT_OUT="telematics_logcat_${TIMESTAMP}.txt"
PKG_ALL="packages_all_${TIMESTAMP}.txt"
SVC_ALL="services_all_${TIMESTAMP}.txt"
WIN_TMP="window_dump_${TIMESTAMP}.tmp"

# 전수 목록 선행 추출 (-u 실패 시 기본 pm list로 자동 폴백)
pm list packages -f -u 2>/dev/null > "$PKG_ALL"
if [ ! -s "$PKG_ALL" ]; then
    pm list packages -f 2>/dev/null > "$PKG_ALL"
fi
service list 2>/dev/null > "$SVC_ALL"
dumpsys window windows 2>/dev/null > "$WIN_TMP"

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
echo "SDK Version: $(getprop ro.build.version.sdk 2>/dev/null)" >> "$OUT"
echo "Boot Completed: $(getprop sys.boot_completed 2>/dev/null)" >> "$OUT"

echo "" >> "$OUT"
echo "--- [2. CURRENT TOP WINDOW & FOCUS] ---" >> "$OUT"
filter_exact "mCurrentFocus|mFocusedApp|mFocus|Window #" < "$WIN_TMP" >> "$OUT"

echo "" >> "$OUT"
echo "--- [3. TOP ACTIVITY & ACTIVITY STACK] ---" >> "$OUT"
dumpsys activity top 2>/dev/null >> "$OUT"

echo "" >> "$OUT"
echo "--- [4. ALL RUNNING ACTIVITIES (FILTERED)] ---" >> "$OUT"
dumpsys activity activities 2>/dev/null | filter_exact "Stack #|TaskRecord|Hist #" >> "$OUT"

echo "" >> "$OUT"
echo "--- [5. ACTIVE NOTIFICATIONS] ---" >> "$OUT"
dumpsys notification 2>/dev/null | filter_exact "NotificationRecord|pkg=|tag=|id=" >> "$OUT"

echo "" >> "$OUT"
echo "--- [6. TELEMATICS & HKMC PACKAGES INSTALLED] ---" >> "$OUT"
filter_icase "telematics|tmu|bluelink|uvo|gcs|modem|setting|hkmc" < "$PKG_ALL" >> "$OUT"

echo "" >> "$OUT"
echo "--- [7. RELEVANT RUNNING PROCESSES (PS)] ---" >> "$OUT"
PS_OUT=$(ps 2>/dev/null)
case "$PS_OUT" in
    *"
"*"
"*) ;;
    *) PS_OUT=$(ps -A 2>/dev/null) ;;
esac
printf '%s\n' "$PS_OUT" | filter_icase "telematics|tmu|bluelink|uvo|gcs|modem|hkmc|factory" >> "$OUT"

echo "" >> "$OUT"
echo "--- [8. BINDER SERVICES (SERVICE LIST)] ---" >> "$OUT"
filter_icase "telematics|tmu|bluelink|uvo|gcs|modem|factory|phone|hscan|tm_" < "$SVC_ALL" >> "$OUT"

echo "" >> "$OUT"
echo "--- [9. TELEMATICS & MODEM SYSTEM PROPERTIES] ---" >> "$OUT"
getprop 2>/dev/null | filter_icase "telematics|tmu|modem|bluelink|uvo|gcs|gsm|ril|carrier|hscan" >> "$OUT"

echo "" >> "$OUT"
echo "--- [10. TELEMATICS APP DATA & DATABASE LISTINGS] ---" >> "$OUT"
list_data_dirs /data/data/*telematics* /data/data/*tmu* /data/data/*bluelink* /data/data/*uvo* /data/data/*gcs* >> "$OUT"

echo "" >> "$OUT"
echo "--- [11. FULL WINDOW DUMP (DETAILED)] ---" >> "$OUT"
cat "$WIN_TMP" 2>/dev/null >> "$OUT"

# 12. Logcat extraction (4.4 -t 미지원 대비 폴백 포함)
echo "[*] Extracting recent logcat..."
logcat -d -v time -t 4000 2>/dev/null > "$LOGCAT_OUT"
if [ ! -s "$LOGCAT_OUT" ]; then
    logcat -d -v time 2>/dev/null > "$LOGCAT_OUT"
fi

# 13. Telematics & TMU APKs, ODEX & Framework JAR Extraction (Zero-Find)
echo "[*] Extracting Telematics APKs/ODEX & Framework (Hardened, Zero-Find)..."
APK_DIR="apks"
mkdir -p "$APK_DIR"

CR=$(printf '\r' 2>/dev/null)
filter_icase "telematics|tmu|bluelink|uvo|gcs|hscan" < "$PKG_ALL" | while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$CR}"
    case "$line" in
        package:*=*)
            rest="${line#package:}"
            p="${rest%=*}"
            pkg="${rest##*=}"
            case "$p" in
                *.apk)
                    if [ -f "$p" ]; then
                        case "$pkg" in
                            */*|"")
                                dst_base="${p##*/}"
                                dst_base="${dst_base%.apk}"
                                ;;
                            *)
                                dst_base="$pkg"
                                ;;
                        esac
                        safe_cp "$p" "$APK_DIR/${dst_base}.apk"
                        
                        # 4.4 Dalvik .odex 복사 (동일 디렉터리)
                        odex="${p%.apk}.odex"
                        if [ -f "$odex" ]; then
                            safe_cp "$odex" "$APK_DIR/${dst_base}.odex"
                        fi
                        
                        # ART 런타임 .odex/.vdex 복사 (Android 5.0+ 호환)
                        p_dir="${p%/*}"
                        for art_f in "${p_dir}/oat/arm/${dst_base}.odex" "${p_dir}/oat/arm/${dst_base}.vdex"; do
                            if [ -f "$art_f" ]; then
                                safe_cp "$art_f" "$APK_DIR/${dst_base}.${art_f##*.}"
                            fi
                        done
                    fi
                    ;;
            esac
            ;;
    esac
done

# 4.4 KitKat Dalvik 프레임워크 고정 경로 검사 및 복사 (framework2 및 .odex 포함)
for fw in \
    /system/framework/framework.jar \
    /system/framework/framework.odex \
    /system/framework/framework2.jar \
    /system/framework/framework2.odex \
    /system/framework/services.jar \
    /system/framework/services.odex; do
    if [ -f "$fw" ]; then
        safe_cp "$fw" "$APK_DIR/${fw##*/}"
    fi
done

# 완료 마커 생성 (USB 최상위에 DUMP_SUCCESS.txt 기록하여 정상 완료 보장)
DONE_FILE="DUMP_SUCCESS.txt"
{
    echo "=========================================="
    echo " HKMC Telematics Dump Completed Successfully"
    echo " Timestamp : $(date 2>/dev/null)"
    echo " Product   : $(getprop ro.build.product 2>/dev/null)"
    echo " TargetDir : $(getprop ro.mobis.targetdir 2>/dev/null)"
    echo " SDK Ver   : $(getprop ro.build.version.sdk 2>/dev/null)"
    echo "=========================================="
    echo ""
    echo "[Extracted APKs & Framework]"
    ls -la "$APK_DIR" 2>/dev/null
    echo ""
    echo "[Diagnostic Text Files]"
    ls -la telematics_dump_*.txt packages_all_*.txt services_all_*.txt telematics_logcat_*.txt 2>/dev/null
} > "$DONE_FILE" 2>/dev/null

sync
echo "[+] Telematics dump & APK extraction completed safely at $(date 2>/dev/null)."
exit 0
