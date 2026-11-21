[블루링크 미개통 팝업 진단 덤프 & 순정 APK 추출 툴 사용법]

1. 준비물
   - FAT32로 포맷된 32GB 이하의 일반 USB 메모리 1개

2. USB 세팅 방법
   - 본 폴더에 있는 2개의 파일(NEMESIS.data, NEMESIS.sh)을 
     USB 메모리의 최상위(루트)에 그대로 복사합니다.
   - 올바른 USB 구조:
     E:\ (USB 드라이브 최상위)
       ├── NEMESIS.data
       └── NEMESIS.sh

3. 차량에서 실행 방법
   1) 시동을 걸고 내비게이션 부팅이 완료될 때까지 기다립니다.
      (팝업을 기다릴 필요 없이, 시동 켜진 상태면 언제든 가능합니다!)
   2) 준비한 USB를 차량의 순정 데이터 USB 포트에 연결합니다.
   3) 내비 화면에 NEMESIS 실행 확인 창("Do you want to execute NEMESIS.sh?")이 뜨면 
      [Yes]를 누릅니다.
   4) 약 5~10초 후 "Success" 완료 팝업이 뜨면 USB를 차량에서 분리합니다.

4. 진단 결과 확인
   - USB를 다시 컴퓨터에 연결하면 최상위에 아래 파일 및 폴더가 새로 생성되어 있습니다:
     - apks/                   (Telematics.apk 등 순정 APK 및 프레임워크 바이너리)
     - packages_all_*.txt      (⭐ 차량 내 설치된 전체 패키지 경로 100% 전수 목록)
     - services_all_*.txt      (⭐ tm_hscan_service를 포함한 전체 바인더 서비스 100% 목록)
     - telematics_dump_*.txt   (화면 포커스, 텔레매틱스 프로세스, DB 목록)
     - telematics_logcat_*.txt (상세 시스템 로그)
   - PC로 복귀 후 복사된 apks 폴더를 전달해주시면 JADX 역공학 분석을 진행합니다!
