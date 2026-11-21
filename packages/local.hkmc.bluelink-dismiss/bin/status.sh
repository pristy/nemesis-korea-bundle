#!/system/bin/sh
# ==============================================================================
# NEMESIS application runner for local.hkmc.bluelink-dismiss
# Checks disarm status and reports diagnostic details
# Zero external binary dependency (Zero external tools)
# ==============================================================================

export PATH=/system/xbin:/sbin:/vendor/bin:/system/sbin:/system/bin:$PATH

PREF_DIR="/data/data/com.hkmc.telematics.service/shared_prefs"
SHARD_XML="$PREF_DIR/shard_service_activation_start_setting.xml"
MONTHLY_XML="$PREF_DIR/MonthlyPopupDetails.xml"
BACKUP_DIR="/data/nemesis/backup/local.hkmc.bluelink-dismiss"

# 순수 mksh 문자열 검색 함수 (외부 도구 의존성 0%)
file_contains() {
    _needle="$1"
    _file="$2"
    [ -r "$_file" ] || return 1
    while IFS= read -r _line || [ -n "$_line" ]; do
        case "$_line" in
            *"$_needle"*) return 0 ;;
        esac
    done < "$_file"
    return 1
}

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

echo "=========================================="
echo " Bluelink Nag Auto-Dismiss Status         "
echo "=========================================="

# 1. shard_service_activation_start_setting.xml 상태
if [ -f "$SHARD_XML" ]; then
    if file_contains "2114348400000" "$SHARD_XML"; then
        echo "[O] Shard Setting : DISARMED (2037-01-01 KST)"
    else
        echo "[!] Shard Setting : Active/Custom"
        cat "$SHARD_XML" 2>/dev/null
    fi
else
    echo "[X] Shard Setting : File Not Found"
fi

# 2. MonthlyPopupDetails.xml 상태
if [ -f "$MONTHLY_XML" ]; then
    if file_contains 'name="isNever" value="true"' "$MONTHLY_XML"; then
        echo "[O] Monthly Popup : DISABLED (isNever=true)"
    else
        echo "[!] Monthly Popup : Active"
        cat "$MONTHLY_XML" 2>/dev/null
    fi
else
    echo "[X] Monthly Popup : File Not Found"
fi

# 3. 백업 상태
if [ -d "$BACKUP_DIR" ]; then
    echo "[O] Stock Backup  : Present in $BACKUP_DIR"
else
    echo "[-] Stock Backup  : None"
fi

# 4. 상주 프로세스 상태 (find_pids 사용, 공백 구분 단일 라인 포맷)
PID_SVC=$(echo $(find_pids "com.hkmc.telematics.service"))
PID_VRM=$(echo $(find_pids "com.hkmc.telematics.apps.Vrm.main"))
echo "[*] HKMC_TAppService PID : ${PID_SVC:-Not running}"
echo "[*] HKMC_TAppVRM PID     : ${PID_VRM:-Not running}"
echo "=========================================="
exit 0
