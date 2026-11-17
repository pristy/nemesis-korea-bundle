# Nemesis Korea Bundle (네메시스 코리아 번들)

> **한국 현대·기아 Gen5W 순정 내비게이션을 위한 올인원(All-in-One) 무선 카플레이 & 안드로이드 오토 USB 설치 팩**  
> *One USB stick for everything: Wireless CarPlay & Android Auto on Korean Hyundai/Kia Gen5W systems.*

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](LICENSE)
[![Target: Gen5W KOR](https://img.shields.io/badge/Target-Gen5W_S5W__M_KOR-green.svg)](#지원-차량-목록-43종-이상-검증-완료)

---

## 초보자를 위한 빠른 시작 가이드

컴퓨터나 차량 시스템에 익숙하지 않은 사용자도 아래 3단계를 순서대로 진행하시면 10분 내에 무선 안드로이드 오토 및 카플레이를 활성화할 수 있습니다.

### 1. 준비물
1. **32GB 이하 USB 메모리 1개** (FAT32 형식 포맷)
2. **배포 파일 (용도에 맞게 택1)**
   * **Stable (안정 버전, 권장):** `nemesis-korea-bundle-v1.0.1-stable-usb.zip`  
     *(검증된 정식 버전 조합: HMG-API 1.0.2 + Korea Projection 1.7.3)*
   * **Latest (최신 버전):** `nemesis-korea-bundle-v1.0.1-latest-usb.zip`  
     *(최신 기능 및 개선 사항 우선 적용: HMG-API 1.1.0-beta.1 + Korea Projection 1.7.4)*

---

### 2. [PC] USB 메모리에 파일 복사

1. USB를 컴퓨터에 연결한 후 **마우스 우클릭 -> [포맷] -> 파일 시스템을 [FAT32]**로 선택하고 [시작]을 누릅니다.
2. 다운로드받은 `nemesis-korea-bundle-v1.0.1-*-usb.zip` 파일(Stable 또는 Latest)의 **압축을 해제**합니다.
3. 압축 해제된 폴더 안의 내용물을 **USB 메모리의 최상위(루트)에 그대로 복사**합니다.

> [!IMPORTANT]
> **주의사항**  
> 폴더째로 복사하지 마세요. USB 드라이브를 열었을 때 아래 구조처럼 파일들이 바로 위치해야 합니다.
> ```text
> USB 드라이브 (E:\)
>  ├── ota_package.tar
>  ├── NEMESIS.data
>  ├── README.txt
>  └── packages/          <-- 폴더 그대로 복사
>       ├── hmgapi.zip
>       └── korea.projection.zip
> ```

---

### 3. [차량] 설치 3단계

> [!NOTE]
> 차량 배터리 방전을 방지하기 위해 **시동을 켠 상태(엔진 시동 또는 하이브리드 READY)**에서 진행하세요.

#### [1단계] USB 연결 및 코어 설치
1. 준비한 USB를 **차량의 순정 데이터 USB 포트(스마트폰 유선 연결 포트)**에 연결합니다.  
   *(화면에 "지원하지 않는 파일 형식" 알림이 나타나도 정상이니 무시하시면 됩니다).*
2. 내비게이션 화면에서 **[설정] -> [일반] -> [SW 정보/업데이트]** 메뉴로 이동합니다.
3. 화면 빈 공간을 **왼쪽 5번 -> 오른쪽 1번** 연속으로 터치합니다.
4. 비밀번호 입력 창이 나타나면 해당 차종/펌웨어 버전의 엔지니어링 모드 비밀번호를 입력합니다.
5. 엔지니어링 모드 화면에서 **[USB Copy] -> [DSP] -> [Update OTA]** 버튼을 터치합니다.
6. 화면에 진행 메시지가 표시되고 **내비게이션이 자동으로 1회 재부팅**됩니다.  
   *(주의: 이때 USB를 분리하지 마시고 그대로 연결해 두세요).*

#### [2단계] 패키지 화면 설치
1. 내비게이션이 다시 켜지면 잠시 후 화면에 **패키지 설치 목록 창(Package Store)**이 자동으로 열립니다.
2. 목록에서 **`HMG-API`** 항목의 **[Install]**을 먼저 터치하여 설치합니다.
3. 설치 완료 후 그 아래 **`Korea Projection`** 항목의 **[Install]**을 터치하여 설치합니다.
4. 화면에 **"설정을 마쳤습니다"** 알림이 나타날 때까지 약 1~2분간 대기합니다.

#### [3단계] USB 분리 및 완전 재부팅 (필수 단계)
1. **USB 메모리를 차량에서 분리합니다.**
2. 시동만 끌 경우 절전 대기 모드(QuickBoot)로 유지되어 변경된 시스템 설정이 반영되지 않습니다.
3. 오디오 볼륨 노브 근처의 **작은 리셋 구멍(RESET 핀홀)을 볼펜 끝이나 클립으로 1초간 눌러 완전 재부팅**합니다.  
   *(화면이 꺼지며 현대/기아 로고와 함께 시스템이 콜드 부팅됩니다).*

---

### 무선 연결 확인
내비게이션 부팅이 완료되면 스마트폰의 **Wi-Fi와 블루투스를 켜고 차량과 블루투스로 페어링**합니다.  
케이블 연결 없이 화면에 **무선 안드로이드 오토 또는 무선 카플레이(티맵, 네이버지도, 카카오내비 등)가 자동으로 실행**됩니다.

> [!TIP]
> **안드로이드 오토가 자동으로 연결되지 않을 때 (★ 순정 내비 업데이트 후 필수 조치)**  
> 내비의 Launch 화면이 🟢 **초록색("무선 카플레이·안드로이드 오토 준비됨")**인데도 팝업이 안 뜨거나 연결되지 않는다면, 바이너리나 차량 시스템 문제가 아니라 **스마트폰의 기존 Android Auto 앱 캐시/세션 충돌** 때문입니다:
> 1. 스마트폰 **[설정] ➔ [애플리케이션] ➔ [Android Auto] ➔ [저장공간]**으로 이동합니다.
> 2. **[데이터 삭제]** 및 **[캐시 삭제]**를 실행하여 이전 세션 찌꺼기를 초기화합니다.
> 3. 스마트폰과 내비 양쪽에서 **블루투스 페어링 등록을 삭제한 후 다시 연결**합니다.
> 4. 내비 화면에 나타나는 **"무선 Android Auto 사용"** 팝업에서 **[사용]**을 누르면 즉시 정상 연동됩니다.  
> *(자세한 내용은 [문제 해결 가이드](docs/troubleshooting.md#3-순정-내비-업데이트-후-무선-안드로이드-오토-연결-불가-해결-실전-해결기)를 참조하세요).*

---

## 지원 차량 목록 (43종 이상 검증 완료)

[설정] > [일반] > [SW 정보]에서 버전명에 **`S5W_M`**이 명시된 10.25인치 / 12.3인치 와이드 내비게이션 장착 차량

* **현대:**
  * **그랜저:** 2021 2.5 가솔린 (`IGPE`), 3.0 LPI (`IGPE21`), 하이브리드 (`IGPEHEV`)
  * **쏘나타:** DN8 2.0 가솔린, 하이브리드 (`DN822HEV`), 2022 LPI
  * **아반떼:** CN7 가솔린, 하이브리드, 아반떼 N
  * **싼타페:** TM PE (`TMFL`)
  * **투싼:** NX4 가솔린, 하이브리드
  * **팰리세이드:** LX2 / **아이오닉 5:** NE EV / **코나:** OS EV / **캐스퍼:** AX1 / **벨로스터 N:** JS N
* **기아:**
  * **K5:** DL3 가솔린, 하이브리드 (`DL3HEV`), 2022년형
  * **쏘렌토:** MQ4 가솔린, 디젤, 하이브리드 (`MQ4HEV`)
  * **니로:** DE PE 하이브리드, 플러그인 하이브리드, SG2, EV
  * **K7 프리미어:** YG PE / **K8:** GL3 하이브리드
  * **카니발:** KA4 / **스포티지:** NQ5 / **EV6:** CV EV / **스팅어:** CK PE / **셀토스:** SP2
* **제네시스:** G70 (`IKFL`)

---

## 순정 복원 방법 (Wipe / 원상복구)

차량 정기 점검 또는 보증 수리 입고 시 언제든지 출고 당시의 순정 상태로 100% 롤백할 수 있습니다:
1. 내비게이션 또는 스티어링 휠의 `MAP` (또는 `NAV`) 버튼을 **1.5초 내에 3회 연속 클릭**합니다.
2. NEMESIS 매니저 화면이 열리면 **[Settings] -> [Wipe NEMESIS]** 메뉴를 선택하고 [Yes]를 누릅니다.
3. 시스템이 재부팅되면서 백업되어 있던 순정 파일들이 복원되고 **완전한 순정 상태로 복구**됩니다.

---

## 번들 직접 빌드하기

파이썬 환경이 설치된 PC에서 언제든 최신 소스로 번들을 직접 패키징할 수 있습니다:

```bash
# 전체 채널(Stable + Latest) 빌드
python scripts/build_bundle.py --channel all

# 안정 버전(Stable)만 빌드
python scripts/build_bundle.py --channel stable

# 최신 버전(Latest)만 빌드
python scripts/build_bundle.py --channel latest
```

---

## 문제 해결 및 참고 문서
* [완전 재부팅(Hard Reset) 핀홀 위치 및 방법](docs/troubleshooting.md#1-완전-재부팅hard-reset-가이드-필수-단계)
* [순정 원상복구(Wipe) 방법 안내](docs/troubleshooting.md#2-순정-원상복구-wipe--출고-상태-복원)
* [순정 내비 업데이트 후 무선 연결 장애 해결 (안드로이드 오토 캐시 삭제)](docs/troubleshooting.md#3-순정-내비-업데이트-후-무선-안드로이드-오토-연결-불가-해결-실전-해결기)

---

## 면책 조항 (Disclaimer)

본 소프트웨어는 오픈소스 커뮤니티의 리버스 엔지니어링 연구 성과물을 기반으로 제작된 패키징 도구입니다. 본 패키지 및 스크립트 사용으로 인해 발생하는 차량 인포테인먼트 시스템의 오작동, 벽돌 현상, 제조사 무상 보증 수리 거부 등의 모든 결과에 대한 책임은 사용자 본인에게 있습니다.

---

## 크레딧 및 라이선스 (Credits & License)

본 프로젝트는 **GNU Affero General Public License v3.0 (AGPL-3.0)**을 준수합니다.

* **[NEMESIS](https://github.com/xwtk/hmg_nemesis)**: Copyright (c) 2024-2026 Gor Mirzoyan (`xwtk`) (GNU AGPL-3.0)
* **[HMG-API](https://github.com/Open-HMG/HMG-API)**: Copyright (c) Bryan Lieberman (`VysseCodes`), Open-HMG contributors (GNU AGPL-3.0)
* **[Korea Projection](https://github.com/StopDragon/korea-projection)**: Copyright (c) StopDragon (GNU AGPL-3.0)
* **Nemesis Korea Bundle**: Copyright (c) 2026 pristy (GNU AGPL-3.0)

상세 라이선스 전문은 [LICENSE](LICENSE)를, 하위 컴포넌트 저작권 고지는 [NOTICE.md](NOTICE.md)를 참조하세요.
