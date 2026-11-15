# NOTICE

Nemesis Korea Bundle
Copyright (c) 2026 pristy

본 소프트웨어는 오픈소스 리버스 엔지니어링 프로젝트와 여러 서드파티 오픈소스 소프트웨어를 기반으로 구성 및 패키징되었습니다. 각 컴포넌트의 저작권 및 출처는 다음과 같습니다.

---

## 1. 상위 프로젝트 및 번들 컴포넌트 출처 (Upstream Projects & Components)

### NEMESIS
* **저작권 (Copyright)**: Copyright (c) 2024-2026 Gor Mirzoyan (`xwtk`)
* **저장소 (Repository)**: [https://github.com/xwtk/hmg_nemesis](https://github.com/xwtk/hmg_nemesis)
* **라이선스 (License)**: GNU Affero General Public License v3.0 (AGPL-3.0)
* **포함/사용 구성요소**:
  * `ota_package.tar`: 엔지니어링 모드(DSP) 진입 취약점을 통한 네메시스 매니저 및 코어 프레임워크 인스톨러
  * `NEMESIS.data`: 패키지 매니저 메타데이터 및 다중 패키지 로더 구조

### HMG-API
* **저작권 (Copyright)**: Copyright (c) 2024-2026 Bryan Lieberman (`VysseCodes`), Open-HMG contributors
* **저장소 (Repository)**: [https://github.com/Open-HMG/HMG-API](https://github.com/Open-HMG/HMG-API)
* **라이선스 (License)**: GNU Affero General Public License v3.0 (AGPL-3.0)
* **포함/사용 구성요소**:
  * `hmgapi.zip` (`hmgapi-1.0.2-nemesis.zip`, `hmgapi-1.1.0-beta.1-nemesis.zip`): 모드 런타임 매니저, 훅 엔진(Hook Engine), 백그라운드 데몬(`hmgapid`) 및 무선 프로젝션 코어 서비스

### Korea Projection
* **저작권 (Copyright)**: Copyright (c) StopDragon
* **저장소 (Repository)**: [https://github.com/StopDragon/korea-projection](https://github.com/StopDragon/korea-projection)
* **라이선스 (License)**: GNU Affero General Public License v3.0 (AGPL-3.0)
* **포함/사용 구성요소**:
  * `korea.projection.zip` (`korea-projection-1.7.3-usb.zip`, `korea-projection-1.7.4-beta.2-usb.zip`): 한국 현대·기아 순정 내비게이션 전용 Wi-Fi 핫스팟 제어 서비스, 무선 카플레이/안드로이드 오토 연결 패치 및 상태 관리 애플리케이션

---

## 2. 라이선스 및 소스코드 공개 고지 (License & Source Availability)

* 본 프로젝트(Nemesis Korea Bundle) 및 포함된 모든 상위 컴포넌트는 **GNU Affero General Public License v3.0 (AGPL-3.0)**의 조건을 따릅니다.
* 라이선스 전문은 본 저장소의 [LICENSE](LICENSE) 파일에서 확인하실 수 있습니다.
* AGPL-3.0 규정에 따라, 본 패키징 번들을 생성하는 빌드 스크립트([scripts/build_bundle.py](scripts/build_bundle.py)) 및 관련 템플릿 파일은 모두 공개되어 있습니다.
* 각 상위 컴포넌트의 원본 소스코드는 상단에 명시된 공식 GitHub 저장소를 통해 열람 및 다운로드할 수 있습니다.

---

## 3. 면책 고지 (Disclaimer)

본 패키징 도구와 스크립트는 차량 인포테인먼트 연구 및 상호 운용성 향상을 목적으로 제작되었습니다. 차량 시스템 변경으로 인한 결과(시스템 오류, 보증 수리 제한 등)에 대한 법적 책임은 사용자 본인에게 있습니다.
