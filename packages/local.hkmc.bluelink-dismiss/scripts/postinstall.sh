#!/system/bin/sh
# ==============================================================================
# NEMESIS postinstall for local.hkmc.bluelink-dismiss
# Target: Hyundai/Kia Gen5W Standard Navigation (Android 4.4.2 KitKat / SDK 19)
# ==============================================================================

export PATH=/system/xbin:/sbin:/vendor/bin:/system/sbin:/system/bin:$PATH
umask 022

# 0. 비대상 차량 가드
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

cleanup() {
    rm -f "$TMP_SHARD" "$TMP_MONTHLY" 2>/dev/null || true
}
trap cleanup EXIT
trap 'exit 143' TERM
trap 'exit 130' INT

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

kill_telematics_processes() {
    for _p in com.hkmc.telematics.service com.hkmc.telematics.apps.Vrm.main; do
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

# 2. 백업 디렉터리 준비 및 원본 백업 보존 (0바이트 제외)
mkdir -p "$BACKUP_DIR" 2>/dev/null
if [ -s "$SHARD_XML" ] && [ ! -s "$BACKUP_DIR/shard_service_activation_start_setting.xml" ]; then
    cat "$SHARD_XML" > "$BACKUP_DIR/shard_service_activation_start_setting.xml" 2>/dev/null
    echo "[+] Original shard_service_activation_start_setting.xml backed up."
fi
if [ -s "$MONTHLY_XML" ] && [ ! -s "$BACKUP_DIR/MonthlyPopupDetails.xml" ]; then
    cat "$MONTHLY_XML" > "$BACKUP_DIR/MonthlyPopupDetails.xml" 2>/dev/null
    echo "[+] Original MonthlyPopupDetails.xml backed up."
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

# 5. 동일 디렉터리 내 임시 파일 권한 선적용
chown 1000:1000 "$TMP_SHARD" 2>/dev/null || chown system:system "$TMP_SHARD" 2>/dev/null
chmod 666 "$TMP_SHARD" 2>/dev/null

chown 1000:1000 "$TMP_MONTHLY" 2>/dev/null || chown system:system "$TMP_MONTHLY" 2>/dev/null
chmod 660 "$TMP_MONTHLY" 2>/dev/null

# 6. 듀얼 프로세스 종료
echo "[*] Terminating telematics and VRM services to prevent memory cache rollback..."
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