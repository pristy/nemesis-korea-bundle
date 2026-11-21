#!/system/bin/sh
# ==============================================================================
# NEMESIS preuninstall for local.hkmc.bluelink-dismiss
# Restores original SharedPreferences XMLs or clears disarm flags to stock defaults
# Target: Hyundai/Kia Gen5W Standard Navigation (Android 4.4.2 KitKat / SDK 19)
# Hardened for Android 4.4.2 Toolbox & mksh:
#   1. Non-telematics unit guard (skips cleanly if package absent)
#   2. Separated trap cleanup
#   3. Deduplicated /proc + ps process lookup (Zero external tool dependency)
#   4. In-directory temp files (.tmp.$$)
#   5. Size verification [ -s "$TMP" ] before move & mv return-code verification
#   6. Dual process termination (HKMC_TAppService + HKMC_TAppVRM)
#   7. Conditional backup cleanup only on verified rollback
#   8. Non-stopped respawn (kill -9 only on reload) & Double sync
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
BACKUP_DIR="/data/nemesis/backup/local.hkmc.bluelink-dismiss"

TMP_RESTORE="$PREF_DIR/.shard_restored.tmp.$$"
TMP_RESTORE_M="$PREF_DIR/.monthly_restored.tmp.$$"

# 임시 파일 자동 정리 및 시그널 분리 trap
cleanup() {
    rm -f "$TMP_RESTORE" "$TMP_RESTORE_M" 2>/dev/null || true
}
trap cleanup EXIT
trap 'exit 143' TERM
trap 'exit 130' INT

# 4.4.2 Toolbox/BusyBox 호환 순수 mksh 프로세스 PID 검색 함수 (중복 출력 방지 및 컬럼 순서 대응)
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
                case "$_c2" in
                    [0-9]*) echo "$_c2" ;;
                    *)
                        case "$_c1" in
                            [0-9]*) echo "$_c1" ;;
                        esac
                        ;;
                esac
                ;;
        esac
    done
}

# 작성 전: SharedPreferences RAM 캐시 완전 드롭을 위해 kill -9 수행 (FLAG_STOPPED 부작용 방지)
stop_telematics_processes() {
    for _p in com.hkmc.telematics.service com.hkmc.telematics.apps.Vrm.main; do
        for _pid in $(find_pids "$_p"); do
            [ -n "$_pid" ] && kill -9 "$_pid" 2>/dev/null
        done
    done
}

# 작성 후: FLAG_STOPPED 방지 및 ActivityManager 자동 리스폰 유도를 위해 kill -9만 수행
restart_telematics_processes() {
    for _p in com.hkmc.telematics.service com.hkmc.telematics.apps.Vrm.main; do
        for _pid in $(find_pids "$_p"); do
            [ -n "$_pid" ] && kill -9 "$_pid" 2>/dev/null
        done
    done
}

echo "=========================================="
echo " Bluelink Nag Auto-Dismiss: Preuninstall  "
echo "=========================================="

# 1. SharedPreferences 동기화 충돌 방지를 위해 서비스 양쪽 모두 중단
stop_telematics_processes

ROLLBACK_OK=1

# 2. 백업 파일이 있으면 원본으로 롤백, 없으면 순정 자동생성을 유도하기 위해 파일 삭제
if [ -f "$BACKUP_DIR/shard_service_activation_start_setting.xml" ]; then
    cat "$BACKUP_DIR/shard_service_activation_start_setting.xml" > "$TMP_RESTORE" 2>/dev/null
    if [ -s "$TMP_RESTORE" ]; then
        chown 1000:1000 "$TMP_RESTORE" 2>/dev/null || chown system:system "$TMP_RESTORE" 2>/dev/null
        chmod 666 "$TMP_RESTORE" 2>/dev/null
        if mv "$TMP_RESTORE" "$SHARD_XML" 2>/dev/null; then
            restorecon "$SHARD_XML" 2>/dev/null || true
            echo "[+] Restored original shard_service_activation_start_setting.xml"
        else
            ROLLBACK_OK=0
            echo "[!] Error: Failed to restore shard_service_activation_start_setting.xml"
        fi
    else
        rm -f "$TMP_RESTORE" 2>/dev/null
        ROLLBACK_OK=0
    fi
else
    rm -f "$SHARD_XML" 2>/dev/null
    echo "[+] Removed modified shard_service_activation_start_setting.xml (system will regenerate default)"
fi

if [ -f "$BACKUP_DIR/MonthlyPopupDetails.xml" ]; then
    cat "$BACKUP_DIR/MonthlyPopupDetails.xml" > "$TMP_RESTORE_M" 2>/dev/null
    if [ -s "$TMP_RESTORE_M" ]; then
        chown 1000:1000 "$TMP_RESTORE_M" 2>/dev/null || chown system:system "$TMP_RESTORE_M" 2>/dev/null
        chmod 660 "$TMP_RESTORE_M" 2>/dev/null
        if mv "$TMP_RESTORE_M" "$MONTHLY_XML" 2>/dev/null; then
            restorecon "$MONTHLY_XML" 2>/dev/null || true
            echo "[+] Restored original MonthlyPopupDetails.xml"
        else
            ROLLBACK_OK=0
            echo "[!] Error: Failed to restore MonthlyPopupDetails.xml"
        fi
    else
        rm -f "$TMP_RESTORE_M" 2>/dev/null
        ROLLBACK_OK=0
    fi
else
    rm -f "$MONTHLY_XML" 2>/dev/null
    echo "[+] Removed modified MonthlyPopupDetails.xml (system will regenerate default)"
fi

# 롤백이 정상적으로 성공했을 때만 백업 폴더 정리
if [ "$ROLLBACK_OK" -eq 1 ]; then
    rm -rf "$BACKUP_DIR" 2>/dev/null
else
    echo "[!] Warning: Rollback had errors, preserving backup directory: $BACKUP_DIR"
fi

# 3. 서비스 자동 리스폰 유도 (am force-stop 없이 kill -9만 수행하여 순정 파일 로드 유도)
restart_telematics_processes

# 4. 버퍼 플러시
sync
sync

# 5. 토스트 알림
am broadcast -a com.hkmc.intent.action.TOAST \
    -e com.hkmc.intent.extra.TOAST_MESSAGE "블루링크 팝업 설정이 순정으로 복구되었습니다." \
    --ez com.hkmc.intent.extra.TOAST_POPUPSHOWING true >/dev/null 2>&1 || true

echo "[SUCCESS] Uninstallation completed: reverted to stock behavior."
exit 0
