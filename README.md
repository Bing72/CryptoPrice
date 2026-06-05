# CryptoPrice

CryptoPrice는 macOS 메뉴바에서 암호화폐 두 종목의 현재가와 24시간 변동률을 표시하는 Cocoa 앱입니다. 앱은 Dock 아이콘 없이 상태바 아이템(`NSStatusItem`)으로 동작하며, 기본 표시 종목은 `BTCUSDT`와 `ETHUSDT`입니다.

## 주요 기능

- 메뉴바에 두 종목의 가격과 24시간 변동률 표시
- 앱 시작 직후 가격 갱신
- 10초 주기 자동 갱신
- 메뉴에서 코인 1/코인 2 심볼 직접 입력
- 변동률이 0 이상이면 초록색, 음수이면 분홍색으로 표시
- API 키 없이 Binance와 Upbit 공개 API 사용

## 심볼 규칙

입력한 문자열의 접미사로 API 제공자를 선택합니다.

| 입력 예시 | 처리 방식 | 호출 API |
| --- | --- | --- |
| `BTCUSDT` | Binance Spot 심볼 그대로 조회 | `https://api.binance.com/api/v3/ticker/24hr` |
| `BTCPERP` | `PERP`를 `USDT`로 변환해 Binance USDT-M Futures 조회 | `https://fapi.binance.com/fapi/v1/ticker/24hr` |
| `BTCKRW` | `KRW` 앞부분을 코인명으로 보고 Upbit `KRW-BTC` 마켓 조회 | `https://api.upbit.com/v1/ticker` |

현재 입력값은 앱 실행 중에만 유지됩니다. 설정 저장 기능은 아직 구현되어 있지 않습니다.

## 프로젝트 구조

```text
CryptoPrice/
├─ CryptoPrice/
│  ├─ AppDelegate.swift              # 메뉴바 앱 진입점, 메뉴 구성, 가격 조회, 표시 업데이트
│  ├─ ViewController.swift           # 현재 화면 로직이 없는 Xcode 템플릿 컨트롤러
│  ├─ CryptoPrice.entitlements       # sandbox/network entitlement
│  ├─ Assets.xcassets/
│  └─ Base.lproj/Main.storyboard     # hidden window와 빈 ViewController 포함
├─ CryptoPrice.xcodeproj/
├─ CryptoPriceTests/                 # 현재 Swift Testing 템플릿 수준
└─ CryptoPriceUITests/               # 현재 앱 launch 중심 UI 테스트
```

## 요구 환경

- macOS 앱 프로젝트
- Xcode 16.3에서 생성된 프로젝트 설정
- macOS deployment target: 15.3
- Swift language version: 5.0
- 앱 번들 ID: `bing.CryptoPrice`

이 저장소를 검토한 환경은 Windows라서 `xcodebuild`/`swift` 실행 검증은 하지 못했습니다. 빌드와 테스트는 macOS + Xcode 환경에서 확인해야 합니다.

## 실행

macOS에서 Xcode로 프로젝트를 엽니다.

```bash
open CryptoPrice.xcodeproj
```

또는 Xcode CLI가 설치된 환경에서 빌드합니다.

```bash
xcodebuild -project CryptoPrice.xcodeproj -scheme CryptoPrice build
```

저장소에는 공유 `.xcscheme` 파일이 포함되어 있지 않고 사용자별 scheme 관리 파일만 있습니다. 위 명령이 scheme을 찾지 못하면 Xcode에서 scheme을 공유 설정으로 저장하거나 `xcodebuild -list -project CryptoPrice.xcodeproj`로 사용 가능한 scheme을 확인하세요.

## 테스트

macOS + Xcode 환경에서 다음 명령을 사용할 수 있습니다.

```bash
xcodebuild -project CryptoPrice.xcodeproj -scheme CryptoPrice test
```

현재 테스트는 Xcode 템플릿 수준입니다.

- `CryptoPriceTests/CryptoPriceTests.swift`: 실제 `#expect` 검증 없음
- `CryptoPriceUITests/CryptoPriceUITests.swift`: 앱 launch 중심
- `CryptoPriceUITests/CryptoPriceUITestsLaunchTests.swift`: launch screenshot attachment 생성

가격 조회, 심볼 파싱, HTTP 오류 처리, stale 응답 방어는 아직 자동 테스트로 검증되지 않습니다.

## 외부 API 의존성

앱은 다음 공개 API에 직접 의존합니다.

- Binance Spot 24hr ticker
- Binance USDT-M Futures 24hr ticker
- Upbit ticker

네트워크 장애, API rate limit, 잘못된 심볼, 응답 포맷 변경 시 메뉴바에는 단순히 `Error`가 표시될 수 있습니다.

## 현재 제약 및 검수 메모

- `AppDelegate`가 앱 수명주기, 메뉴, 입력 모달, 네트워크 요청, JSON 파싱, 포맷팅, UI 표시를 모두 담당합니다.
- 10초 타이머 갱신과 수동 갱신이 겹칠 수 있으며, 느린 이전 응답이 최신 선택 코인 라벨과 섞일 위험이 있습니다.
- 입력 심볼은 공백 제거 외 정규화/검증이 없습니다.
- HTTP status, API 오류, decoding 오류가 구분되지 않습니다.
- `CryptoPrice.entitlements`에는 현재 코드에서 필요성이 확인되지 않은 `network.server`와 user-selected read-only file 권한이 포함되어 있습니다.
- 앱은 `LSUIElement = YES`인 메뉴바 앱이지만 storyboard hidden window와 빈 `ViewController`가 남아 있습니다.

자세한 검수 결과는 [`CODE_REVIEW.md`](CODE_REVIEW.md)를 참고하세요.
