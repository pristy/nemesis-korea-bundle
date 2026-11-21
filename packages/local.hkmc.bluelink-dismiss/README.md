# Bluelink Nag Auto-Dismiss (`local.hkmc.bluelink-dismiss`)

> 현대·기아 Gen5W 순정 내비게이션(Android 4.4.2 KitKat)에서 미개통·기간 만료 시 30일(또는 매월) 주기마다 반복 발생하는 **"서비스 개통 안내(ServiceActivationPopUp)"** 확인창을 영구적으로 억제하는 경량 패키지입니다.

---

## 💡 원리 및 아키텍처 (Zero-Daemon / Zero-Wear)

1. **데몬 없는 영구 억제 (Zero-Overhead):**
   - 백그라운드에서 매 0.05초마다 화면 윈도우를 감시하는 폴링 데몬 방식은 CPU, 배터리, 암전류 소모를 유발합니다.
   - 본 패키지는 백그라운드 상주 프로세스를 일절 구동하지 않으며, 안드로이드 텔레매틱스 서비스(`com.hkmc.telematics.service` 및 `HKMC_TAppVRM`)가 내부적으로 참조하는 팝업 만료 시각(`extra_remind_time`)을 안전한 미래 시점(2037년 1월 1일 GMT+9)으로 이동시킵니다.
   - 내부 검증 로직(`b.v(Context)`)에서 현재 시각과 29일 경과 여부를 비교할 때 항상 `false`를 반환하므로, 팝업 인텐트(`startActivity`) 자체가 원천적으로 발행되지 않습니다.

2. **크래시(Force Close) 원천 차단:**
   - 안드로이드 컴포넌트를 `pm disable`로 강제 비활성화할 경우, `HKMC_TAppService`의 `CommonUtils.bn.run()` 호출부에 `try-catch`가 없어 `ActivityNotFoundException` 발생과 함께 시스템 앱 강제 종료 팝업이 뜨는 치명적 문제가 발생합니다.
   - 본 패키지는 서비스와 액티비티를 비활성화하지 않고 정상 구동 상태를 유지한 채 설정 트리거만 억제하므로 시스템 안정성이 100% 보장됩니다.

3. **32비트 Y2038 오버플로 방어:**
   - Android 4.4.2 KitKat(SDK 19, 32-bit Dalvik/Linux) 환경에서 2038년 1월 19일을 초과하는 날짜(예: 2099년)를 사용할 경우 부호 있는 32비트 정수 오버플로가 발생하여 팝업이 즉시 뜨거나 시스템 크래시를 유발할 수 있습니다.
   - 본 패키지는 29일 가산 후에도 32비트 상한선(`2147483647`초) 내에 안전하게 머무르는 `2114348400000ms`(2037-01-01 KST)를 적용합니다.

4. **100% 클린 롤백 지원 (Preuninstall):**
   - NEMESIS Manager에서 패키지 삭제 시 설치 전 백업된 원본 파일이 자동 복구되며, 차량 출고 상태로 완벽히 원복됩니다.
