# CryptoPrice 코드 검수 보고서

검수 기준일: 2026-06-05

검수 범위: `CryptoPrice/`, `CryptoPriceTests/`, `CryptoPriceUITests/`, `CryptoPrice.xcodeproj/project.pbxproj`, README 유무

검수 방식: 메인 에이전트 로컬 검사 + 서브에이전트 3개 병렬 검토(`code-reviewer`, `architect`, `writer`)

## 요약

- 최종 권고: **REQUEST CHANGES**
- Architectural Status: **BLOCK**
- CRITICAL: 0
- HIGH: 1
- MEDIUM: 3
- LOW: 2
- README: 기존에는 없음, 이번 작업에서 작성
- 빌드/테스트 실행: 현재 Windows 환경에 `xcodebuild`, `swift`, `sourcekit-lsp`가 없어 macOS 컴파일 검증은 미수행

## 검토 파일

- `CryptoPrice/AppDelegate.swift`
- `CryptoPrice/ViewController.swift`
- `CryptoPrice/CryptoPrice.entitlements`
- `CryptoPrice/Base.lproj/Main.storyboard`
- `CryptoPrice.xcodeproj/project.pbxproj`
- `CryptoPriceTests/CryptoPriceTests.swift`
- `CryptoPriceUITests/CryptoPriceUITests.swift`
- `CryptoPriceUITests/CryptoPriceUITestsLaunchTests.swift`

## CRITICAL

없음.

## HIGH

### 1. 느린/겹친 네트워크 응답이 현재 선택 코인 라벨에 잘못 표시될 수 있음

근거:

- `CryptoPrice/AppDelegate.swift:29-33` 10초 반복 타이머
- `CryptoPrice/AppDelegate.swift:56-57`, `CryptoPrice/AppDelegate.swift:79-80` 수동 입력 직후 즉시 갱신
- `CryptoPrice/AppDelegate.swift:95-99` 요청 타입 판단
- `CryptoPrice/AppDelegate.swift:257-267` 렌더링 시점에 현재 `selectedCoin`/`secondSelectedCoin`을 다시 읽음

요청 URL은 `updatePrice()` 호출 당시의 심볼로 만들어지지만, 응답 완료 후 표시명은 그 시점의 최신 상태를 다시 읽습니다. 네트워크가 느린 상태에서 사용자가 심볼을 바꾸면 이전 가격이 새 코인명과 조합되어 표시될 수 있습니다.

권장 수정:

- `updatePrice()` 시작 시 두 코인의 display/apiSymbol/API 타입을 immutable snapshot으로 캡처
- generation token 또는 request ID를 두고 최신 요청만 UI에 반영
- 가능하면 이전 in-flight task 취소 또는 요청 직렬화

## MEDIUM

### 1. 사용자 입력 심볼을 검증/정규화하지 않고 URL 문자열에 직접 삽입함

근거:

- `CryptoPrice/AppDelegate.swift:54-57`, `CryptoPrice/AppDelegate.swift:77-80` 공백 제거 외 검증 없음
- `CryptoPrice/AppDelegate.swift:103-105`, `CryptoPrice/AppDelegate.swift:149`, `CryptoPrice/AppDelegate.swift:220` 문자열 보간으로 URL 구성

소문자, 특수문자, 잘못된 suffix가 들어오면 API 실패 또는 잘못된 query가 만들어질 수 있습니다.

권장 수정:

- 입력값을 `uppercased()`로 정규화
- 허용 문자와 지원 suffix를 명시적으로 검증
- `URLComponents`와 `URLQueryItem`으로 URL 구성

### 2. 네트워크 오류/HTTP 상태/API 오류를 모두 조용히 `Error`로 축약함

근거:

- `CryptoPrice/AppDelegate.swift:107-117`
- `CryptoPrice/AppDelegate.swift:129-140`
- `CryptoPrice/AppDelegate.swift:151-162`
- `CryptoPrice/AppDelegate.swift:178-188`
- `CryptoPrice/AppDelegate.swift:200-211`
- `CryptoPrice/AppDelegate.swift:222-233`
- `CryptoPrice/AppDelegate.swift:252-255`, `CryptoPrice/AppDelegate.swift:269-270`

`response`와 `error`를 실질적으로 처리하지 않고 `try? JSONSerialization`으로 실패를 숨깁니다. 429/rate limit, 4xx invalid symbol, 5xx 장애, decoding failure가 모두 같은 `Error` 표시로 축약됩니다.

권장 수정:

- `HTTPURLResponse.statusCode` 확인
- `Decodable` 응답 모델 도입
- 네트워크 실패, invalid symbol, rate limit, decoding 실패를 내부 error type으로 구분
- 실패 상태의 색상을 상승/하락 색상과 분리

### 3. 핵심 로직이 `AppDelegate`에 집중되어 테스트가 사실상 비어 있음

근거:

- `CryptoPrice/AppDelegate.swift:88-287` 가격 조회/파싱/포맷팅/UI 업데이트 집중
- `CryptoPriceTests/CryptoPriceTests.swift:13-15` unit test placeholder
- `CryptoPriceUITests/CryptoPriceUITests.swift:25-32` launch 중심 UI test

현재 구조에서는 심볼 파싱, URL 생성, JSON decoding, 오류 처리, stale 응답 방어를 단위 테스트하기 어렵습니다.

권장 수정:

- `PriceService`, `SymbolParser`, `PriceFormatter`, typed response DTO 분리
- `URLSession` 의존성을 주입 가능한 client로 감싸기
- BTCUSDT/BTCKRW/BTCPERP URL 생성, 성공 decoding, HTTP error, stale request 무시 테스트 추가

## LOW

### 1. 메뉴바 앱인데 기본 Window/ViewController/storyboard boilerplate가 남아 있음

근거:

- `CryptoPrice.xcodeproj/project.pbxproj:400`, `CryptoPrice.xcodeproj/project.pbxproj:427` `LSUIElement = YES`
- `CryptoPrice.xcodeproj/project.pbxproj:402`, `CryptoPrice.xcodeproj/project.pbxproj:429` Main storyboard 지정
- `CryptoPrice/Base.lproj/Main.storyboard:685-711` hidden window와 빈 ViewController
- `CryptoPrice/ViewController.swift:10-25` 템플릿 상태

실제 UI는 status item/menu 중심인데 hidden window와 빈 ViewController가 남아 구조 의도가 흐립니다.

권장 수정:

- 메뉴바 전용이면 storyboard/window/ViewController 의존 제거
- 설정 창 계획이 있다면 ViewController에 실제 책임을 부여하고 README에 명시

### 2. 현재 기능보다 넓어 보이는 entitlement

근거:

- `CryptoPrice/CryptoPrice.entitlements:5-12` sandbox, user-selected read-only file, network client/server
- 현재 확인된 네트워크 사용은 외부 API client 요청뿐

`network.server`와 user-selected read-only file entitlement의 필요성이 코드에서 확인되지 않습니다.

권장 수정:

- 수신 서버 기능이 없다면 `com.apple.security.network.server` 제거
- 파일 선택 읽기 기능이 없다면 user-selected read-only entitlement 제거 검토

## 문서화 결과

이번 작업에서 `README.md`를 추가해 다음 항목을 문서화했습니다.

- 앱 개요와 메뉴바 동작
- 심볼 suffix 규칙
- 프로젝트 구조
- 요구 환경
- macOS/Xcode 실행 및 테스트 명령
- 외부 API 의존성
- 현재 테스트/구조 제약

## 검증 상태

현재 환경에서 수행한 검증:

- 저장소 파일 목록 확인
- README 부재 확인 후 작성
- `AppDelegate.swift`, storyboard, entitlements, project 설정 근거 확인
- `xcodebuild`, `swift` 명령 부재 확인
- 서브에이전트 병렬 검수 결과 통합

macOS + Xcode 환경에서 추가로 수행해야 할 검증:

```bash
xcodebuild -list -project CryptoPrice.xcodeproj
xcodebuild -project CryptoPrice.xcodeproj -scheme CryptoPrice build
xcodebuild -project CryptoPrice.xcodeproj -scheme CryptoPrice test
```

## 다음 권장 작업

1. `updatePrice()` stale 응답 방어를 최우선으로 수정
2. 심볼 정규화/검증과 URLComponents 도입
3. 가격 조회/파싱 로직을 `AppDelegate`에서 분리
4. 실질 unit test 추가
5. entitlement 최소화
