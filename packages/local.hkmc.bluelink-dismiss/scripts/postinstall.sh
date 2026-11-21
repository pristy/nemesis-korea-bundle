#!/system/bin/sh
# ==============================================================================
# NEMESIS postinstall for local.hkmc.bluelink-dismiss
# Suppresses unactivated 30-day Bluelink/Kia Connect nag popup by shifting reminder epoch
# Target: Hyundai/Kia Gen5W Standard Navigation (Android 4.4.2 KitKat / SDK 19)
# Zero daemon, zero background CPU/battery overhead, safe 32-bit timestamp
# Hardened for Android 4.4.2 Toolbox & mksh:
#   1. Non-telematics unit guard (skips cleanly if package absent)
#   2. Trap cleanup for temporary files
#   3. Pure /proc + ps process lookup (Zero external tool dependency)
#   4. No printf, no Here-Docs (uses pure shell builtin echo block)
#   5. Size verification [ ! -s "$TMP" ] before any move (zero 0-byte risk)
#   6. Standard plain move command (Toolbox compatible plain mv without flags)
#   7. Strict permissions (shard 0666, monthly 0660, chown 1000:1000)
#   8. Double sync before hardware reset
# ==============================================================================

export PATH=/system/xbin:/sbin:/vendor/bin:/system/sbin:/system/bin:$PATH
umask 022

# 0. 비대상 차량 가드 (텔레매틱스 서비스가 없는 차량은 안전하게 스킵)
if [ ! -d "/data/data/com.hkmc.telematics.service" ]; then
    echo "[-] Target telematics package directory not found. Skipping."
    exit 0
fi

PREF_DIR="/data/data/com.hkmc.telematics.service/shared_prefs"
SHARD_XML="$PREF_DIR/shard_service_activation_start_setting.xml"
MONTHLY_XML="$PREF_DIR/MonthlyPopupDetails.xml"

TMP_SHARD="$PREF_DIR/.shard_activation.tmp.$$"
TMP_MONTHLY="$PREF_DIR/.monthly_popup.tmp.$$"
BACKUP_DIR="/data/nemesis/backup/local.hkmc.bluelink-dismiss"

# 임시 파일 자동 정리 trap
trap 'rm -f "$TMP_SHARD" "$TMP_MONTHLY" 2>/dev/null' EXIT INT TERM

# 4.4.2 Toolbox 호환 순수 mksh 프로세스 PID 검색 함수 (외부 도구 의존성 0%)
find_pids() {
    _target="$1"
    for _pdir in /proc/[0-9]*; do
        [ -r "$_pdir/cmdline" ] || continue
        _cmd=""
        IFS= read -r _cmd < "$_pdir/cmdline" 2>/dev/null
        _cmd="${_cmd%% *}"
        if [ "$_cmd" = "$_target" ]; then
            echo "${_pdir#/proc/}"
        fi
    done
    ps 2>/dev/null | while read -r _u _p _rest; do
        case "$_rest" in
            *"$_target")
                echo "$_p"
                ;;
        esac
    done
}

stop_telematics_processes() {
    for _p in com.hkmc.telematics.service com.hkmc.telematics.apps.Vrm.main; do
        am force-stop "$_p" 2>/dev/null
        for _pid in $(find_pids "$_p"); do
            [ -n "$_pid" ] && kill -9 "$_pid" 2>/dev/null
        done
    done
}

echo "=========================================="
echo " Bluelink Nag Auto-Dismiss: Postinstall   "
echo "=========================================="

# 1. 대상 디렉터리 검증 및 생성
if [ ! -d "$PREF_DIR" ]; then
    echo "[*] Creating target shared_prefs directory: $PREF_DIR"
    mkdir -p "$PREF_DIR" 2>/dev/null
    chown 1000:1000 "$PREF_DIR" 2>/dev/null || chown system:system "$PREF_DIR" 2>/dev/null
    chmod 771 "$PREF_DIR" 2>/dev/null
fi

# 2. 백업 디렉터리 준비 및 원본 백업 보존
mkdir -p "$BACKUP_DIR" 2>/dev/null
if [ -f "$SHARD_XML" ] && [ ! -f "$BACKUP_DIR/shard_service_activation_start_setting.xml" ]; then
    cat "$SHARD_XML" > "$BACKUP_DIR/shard_service_activation_start_setting.xml" 2>/dev/null
    echo "[+] Original shard_service_activation_start_setting.xml backed up."
fi
if [ -f "$MONTHLY_XML" ] && [ ! -f "$BACKUP_DIR/MonthlyPopupDetails.xml" ]; then
    cat "$MONTHLY_XML" > "$BACKUP_DIR/MonthlyPopupDetails.xml" 2>/dev/null
    echo "[+] Original MonthlyPopupDetails.xml backed up."
fi

# 3. [순수 echo 블록 작성] 외부 바이너리나 Here-Doc 의존 없이 순수 쉘 내장 echo 사용
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

# 4. [0바이트 파괴 방어 검증] 임시 파일 생성 실패 시 원본 보호를 위해 즉시 중단
if [ ! -s "$TMP_SHARD" ] || [ ! -s "$TMP_MONTHLY" ]; then
    echo "[!] Error: Generated temp XML is empty! Aborting to protect original files."
    rm -f "$TMP_SHARD" "$TMP_MONTHLY" 2>/dev/null
    exit 1
fi

# 5. [동일 디렉터리 권한 선적용] 원본 소유권(system:system 1000:1000) 및 권한(0666/0660) 설정
chown 1000:1000 "$TMP_SHARD" 2>/dev/null || chown system:system "$TMP_SHARD" 2>/dev/null
chmod 666 "$TMP_SHARD" 2>/dev/null

chown 1000:1000 "$TMP_MONTHLY" 2>/dev/null || chown system:system "$TMP_MONTHLY" 2>/dev/null
chmod 660 "$TMP_MONTHLY" 2>/dev/null

# 6. [듀얼 프로세스 종료] HKMC_TAppService + HKMC_TAppVRM 동시 종료로 RAM 캐시 동기화 방지
echo "[*] Terminating telematics and VRM services to prevent memory cache rollback..."
stop_telematics_processes

# 7. [Toolbox 호환 원자적 교체] 옵션 없는 순수 mv로 원자적(atomic rename) 교체
mv "$TMP_SHARD" "$SHARD_XML" 2>/dev/null
mv "$TMP_MONTHLY" "$MONTHLY_XML" 2>/dev/null

chown 1000:1000 "$SHARD_XML" 2>/dev/null || chown system:system "$SHARD_XML" 2>/dev/null
chmod 666 "$SHARD_XML" 2>/dev/null

chown 1000:1000 "$MONTHLY_XML" 2>/dev/null || chown system:system "$MONTHLY_XML" 2>/dev/null
chmod 660 "$MONTHLY_XML" 2>/dev/null

restorecon "$SHARD_XML" 2>/dev/null || true
restorecon "$MONTHLY_XML" 2>/dev/null || true

# 8. 프로세스 재기동 유도 (ActivityManager에 의해 새 XML 로드)
stop_telematics_processes

# 9. 디스크 버퍼 강제 플러시
sync
sync

# 10. 보조 토스트 알림
am broadcast -a com.hkmc.intent.action.TOAST \
    -e com.hkmc.intent.extra.TOAST_MESSAGE "블루링크 미개통 팝업 억제 적용 완료 (재부팅 권장)" \
    --ez com.hkmc.intent.extra.TOAST_POPUPSHOWING true >/dev/null 2>&1 || true

echo "[SUCCESS] Bluelink nag popup disarmed until 2037."
echo "[INFO] Hard reboot (RESET pinhole) is recommended for immediate full effect."
exit 0
