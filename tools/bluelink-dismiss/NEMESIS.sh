#!/system/bin/sh
# ==============================================================================
# HKMC Bluelink / Kia Connect Nag Auto-Dismiss Standalone Installer
# Target: Hyundai/Kia Gen5W Standard Navigation (Android 4.4.2 KitKat / SDK 19)
# Execution: Runs as root via NEMESIS USB autorun (cwd = USB root)
# ==============================================================================

export PATH=/system/xbin:/sbin:/vendor/bin:/system/sbin:/system/bin:$PATH
export LD_LIBRARY_PATH=/vendor/lib:/system/lib
umask 022

# 0. 비대상 차량 가드 (텔레매틱스 패키지가 없는 기종은 안전하게 스킵)
if [ ! -d "/data/data/com.hkmc.telematics.service" ]; then
    echo "[-] Telematics service directory not found. Not a telematics head unit. Skipping."
    exit 0
fi

PREF_DIR="/data/data/com.hkmc.telematics.service/shared_prefs"
SHARD_XML="$PREF_DIR/shard_service_activation_start_setting.xml"
MONTHLY_XML="$PREF_DIR/MonthlyPopupDetails.xml"

TMP_SHARD="$PREF_DIR/.shard_activation.tmp.$$"
TMP_MONTHLY="$PREF_DIR/.monthly_popup.tmp.$$"

# [안전장치] 30초 워치독 타이머 (고아 프로세스 및 데드락 방지)
MAIN_PID=$$
(
    read -r MY_REAL_PID rest < /proc/self/stat 2>/dev/null
    SLEEP_PID=""
    trap 'if [ -n "$SLEEP_PID" ]; then kill -9 "$SLEEP_PID" 2>/dev/null; wait "$SLEEP_PID" 2>/dev/null; fi; exit 0' TERM INT
    sleep 30 &
    SLEEP_PID=$!
    wait "$SLEEP_PID" 2>/dev/null

    for f in /proc/[0-9]*/stat; do
        [ -r "$f" ] || continue
        _stat=""
        IFS= read -r _stat < "$f" 2>/dev/null || continue
        c_pid="${_stat%% *}"
        _after="${_stat##*) }"
        _after="${_after#* }"
        c_ppid="${_after%% *}"
        if [ "$c_ppid" = "$MAIN_PID" ] && [ "$c_pid" != "$MY_REAL_PID" ]; then
            kill -9 "$c_pid" 2>/dev/null || true
        fi
    done
    kill -TERM "$MAIN_PID" 2>/dev/null
) &
WATCHDOG_PID=$!

cleanup() {
    trap - EXIT INT TERM
    kill -TERM "$WATCHDOG_PID" 2>/dev/null || true
    wait "$WATCHDOG_PID" 2>/dev/null || true
    rm -f "$TMP_SHARD" "$TMP_MONTHLY" 2>/dev/null || true
    sync; sync
}
trap cleanup EXIT
trap 'exit 143' TERM
trap 'exit 130' INT

# USB 내 불필요한 스왑 파일 정리
rm -f .NEMESIS.sh.swp 2>/dev/null

# 4.4.2 Toolbox/BusyBox 호환 순수 mksh PID 검색 함수 (중복 및 UID 오인 방지)
find_pids() {
    _target="$1"
    _found=0
    for _pdir in /proc/[0-9]*; do
        [ -r "$_pdir/cmdline" ] || continue
        _cmd=""
        IFS= read -r _cmd < "$_pdir/cmdline" 2>/dev/null
        _cmd="${_cmd%% *}"
        if [ "$_cmd" = "$_target" ]; then
            echo "${_pdir#/proc/}"
            _found=1
        fi
    done
    [ "$_found" -eq 1 ] && return 0

    ps 2>/dev/null | while read -r _c1 _c2 _rest; do
        case " $_rest" in
            *" $_target")
                case "$_c1" in
                    ""|*[!0-9]*)
                        case "$_c2" in
                            ""|*[!0-9]*) ;;
                            *) echo "$_c2" ;;
                        esac
                        ;;
                    *) echo "$_c1" ;;
                esac
                ;;
        esac
    done
}

# FLAG_STOPPED 부작용 없이 RAM 캐시 드롭 및 자동 리스폰 유도
kill_telematics_processes() {
    for _p in com.hkmc.telematics.service com.hkmc.telematics.apps.Vrm.main; do
        for _pid in $(find_pids "$_p"); do
            [ -n "$_pid" ] && kill -9 "$_pid" 2>/dev/null
        done
    done
}

TIMESTAMP=$(date +%Y%m%d_%H%M%S 2>/dev/null)
case "$TIMESTAMP" in
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9][0-9][0-9]) ;;
    *) TIMESTAMP="latest" ;;
esac

USB_BACKUP_DIR="backup"
DEV_BACKUP_DIR="/data/nemesis/backup/local.hkmc.bluelink-dismiss"

mkdir -p "$USB_BACKUP_DIR" 2>/dev/null
mkdir -p "$DEV_BACKUP_DIR" 2>/dev/null

echo "=========================================="
echo " HKMC Bluelink Nag Auto-Dismiss Installer "
echo " Timestamp : $TIMESTAMP"
echo " Board     : $(getprop ro.build.product 2>/dev/null)"
echo " BuildVer  : $(getprop ro.build.version.incremental 2>/dev/null)"
echo "=========================================="

# 1. 대상 디렉터리 존재 확인 및 퍼미션 보장
if [ ! -d "$PREF_DIR" ]; then
    echo "[*] Creating target directory: $PREF_DIR"
    mkdir -p "$PREF_DIR" 2>/dev/null
    chown 1000:1000 "$PREF_DIR" 2>/dev/null || chown system:system "$PREF_DIR" 2>/dev/null
    chmod 771 "$PREF_DIR" 2>/dev/null
fi

# 2. 원본 파일 안전 백업 (0바이트 제외, USB 및 단말 내부 동시 보존)
if [ -s "$SHARD_XML" ]; then
    cat "$SHARD_XML" > "$USB_BACKUP_DIR/shard_service_activation_start_setting_${TIMESTAMP}.xml" 2>/dev/null
    if [ ! -s "$DEV_BACKUP_DIR/shard_service_activation_start_setting.xml" ]; then
        cat "$SHARD_XML" > "$DEV_BACKUP_DIR/shard_service_activation_start_setting.xml" 2>/dev/null
    fi
    echo "[+] Backed up original shard_service_activation_start_setting.xml"
fi

if [ -s "$MONTHLY_XML" ]; then
    cat "$MONTHLY_XML" > "$USB_BACKUP_DIR/MonthlyPopupDetails_${TIMESTAMP}.xml" 2>/dev/null
    if [ ! -s "$DEV_BACKUP_DIR/MonthlyPopupDetails.xml" ]; then
        cat "$MONTHLY_XML" > "$DEV_BACKUP_DIR/MonthlyPopupDetails.xml" 2>/dev/null
    fi
    echo "[+] Backed up original MonthlyPopupDetails.xml"
fi

# 3. 순수 쉘 내장 echo 블록으로 임시 XML 작성
{
    echo "<?xml version='1.0' encoding='utf-8' standalone='yes' ?>"
    echo "<map>"
    echo "    <long name=\"extra_remind_time\" value=\"2114348400000\" />"
    echo "    <boolean name=\"extra_remind_value\" value=\"true\" />"
    echo "</map>"
} > "$TMP_SHARD"

{
    echo "<?xml version='1.0' encoding='utf-8' standalone='yes' ?>"
    echo "<map>"
    echo "    <boolean name=\"isNever\" value=\"true\" />"
    echo "    <long name=\"lastChecked\" value=\"2114348400000\" />"
    echo "    <long name=\"lastDayChecked\" value=\"2114348400000\" />"
    echo "</map>"
} > "$TMP_MONTHLY"

# 4. 0바이트 파괴 방어 검증
if [ ! -s "$TMP_SHARD" ] || [ ! -s "$TMP_MONTHLY" ]; then
    echo "[!] Error: Generated temp XML is empty! Aborting to protect original files."
    rm -f "$TMP_SHARD" "$TMP_MONTHLY" 2>/dev/null
    exit 1
fi

# 5. 동일 디렉터리 내 임시 파일 권한 선적용 (system:system 1000:1000, 0666/0660)
chown 1000:1000 "$TMP_SHARD" 2>/dev/null || chown system:system "$TMP_SHARD" 2>/dev/null
chmod 666 "$TMP_SHARD" 2>/dev/null

chown 1000:1000 "$TMP_MONTHLY" 2>/dev/null || chown system:system "$TMP_MONTHLY" 2>/dev/null
chmod 660 "$TMP_MONTHLY" 2>/dev/null

# 6. 듀얼 프로세스 종료 (SharedPreferences RAM 캐시 동기화 충돌 방어)
echo "[*] Stopping HKMC_TAppService and HKMC_TAppVRM..."
kill_telematics_processes

# 7. Toolbox 호환 원자적 교체, .bak 잔여물 제거 및 반환값 검증
if ! mv "$TMP_SHARD" "$SHARD_XML" 2>/dev/null; then
    echo "[!] Error: Failed to replace shard_service_activation_start_setting.xml"
    rm -f "$TMP_SHARD" "$TMP_MONTHLY" 2>/dev/null
    exit 1
fi

if ! mv "$TMP_MONTHLY" "$MONTHLY_XML" 2>/dev/null; then
    echo "[!] Error: Failed to replace MonthlyPopupDetails.xml"
    rm -f "$TMP_MONTHLY" 2>/dev/null
    exit 1
fi

rm -f "${SHARD_XML}.bak" "${MONTHLY_XML}.bak" 2>/dev/null || true

chown 1000:1000 "$SHARD_XML" 2>/dev/null || chown system:system "$SHARD_XML" 2>/dev/null
chmod 666 "$SHARD_XML" 2>/dev/null

chown 1000:1000 "$MONTHLY_XML" 2>/dev/null || chown system:system "$MONTHLY_XML" 2>/dev/null
chmod 660 "$MONTHLY_XML" 2>/dev/null

restorecon "$SHARD_XML" 2>/dev/null || true
restorecon "$MONTHLY_XML" 2>/dev/null || true

# 8. 교체 중 자동 기동된 프로세스 정리 (새 XML 로드 유도)
kill_telematics_processes

# 9. 디스크 버퍼 플러시
sync

# 10. 검증 보고서 작성 (USB 루트에 DISARM_SUCCESS.txt 기록)
SUCCESS_FILE="DISARM_SUCCESS.txt"
{
    echo "========================================================"
    echo " HKMC Bluelink Nag Auto-Dismiss Applied Successfully    "
    echo "========================================================"
    echo " Applied At : $(date 2>/dev/null)"
    echo " Vehicle    : $(getprop ro.build.product 2>/dev/null)"
    echo " TargetDir  : $(getprop ro.mobis.targetdir 2>/dev/null)"
    echo " Incremental: $(getprop ro.build.version.incremental 2>/dev/null)"
    echo ""
    echo "[Target Files Status]"
    ls -la "$SHARD_XML" "$MONTHLY_XML" 2>/dev/null
    echo ""
    echo "[shard_service_activation_start_setting.xml Contents]"
    cat "$SHARD_XML" 2>/dev/null
    echo ""
    echo "[MonthlyPopupDetails.xml Contents]"
    cat "$MONTHLY_XML" 2>/dev/null
    echo ""
    echo "[Backup Files on USB]"
    ls -la "$USB_BACKUP_DIR" 2>/dev/null
    echo "========================================================"
} > "$SUCCESS_FILE" 2>/dev/null

# 11. 보조 토스트 알림 브로드캐스트 (실패해도 무시)
am broadcast -a com.hkmc.intent.action.TOAST \
    -e com.hkmc.intent.extra.TOAST_MESSAGE "블루링크 팝업 억제 완료 (RESET 재부팅 권장)" \
    --ez com.hkmc.intent.extra.TOAST_POPUPSHOWING true >/dev/null 2>&1 || true

echo "[+] Bluelink nag popup successfully disarmed!"
echo "[+] Verification report written to $SUCCESS_FILE"
echo "[+] Done. NEMESIS dialog will display execution complete."
exit 0