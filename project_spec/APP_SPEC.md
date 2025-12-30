# Flutter 앱 명세 — 해양 플라스틱 수거 로봇(수조 시연)

## 목적
- 2x3 격자로 구분된 수조에서 수거 이벤트(위치+사진)를 시각화한다.
- 온라인(라즈베리파이 FastAPI) + 오프라인(시뮬레이션) 모두 데모 가능.

## 핵심 요구
- 격자: 2행 x 3열, `cell_id = row*3 + col` (0~5).
- 이벤트 표시: 해당 칸에 빨간 점(다수 시 Wrap, 6개 초과 시 `+N` 뱃지).
- 점 탭 → 상세 화면(이미지, ID, 시간, 위치).
- 이벤트 로그 화면: 썸네일 + 위치 + 시간, 탭 시 상세로 이동.
- 설정 화면: 라즈베리파이 서버 베이스 URL 저장(SharedPreferences).
- 상태 표시: 연결/미연결/데모 모드.
- 오프라인 데모: “Simulate Event” 버튼으로 랜덤 cell_id + 플레이스홀더 이미지.
- 폴링: 서버 URL 설정 시 `/records` 2초 주기 조회(선택적 `since`).

## 폴더 구조(앱)
- `lib/models/tank_event.dart` : 레코드 모델(JSON 파서, cell 라벨).
- `lib/services/event_repository.dart` : `/records` GET, 이미지 URL 보정.
- `lib/state/event_controller.dart` : 상태/시뮬레이션/폴링.
- `lib/state/settings_controller.dart` : URL 로드/저장.
- `lib/ui/screens/` : 대시보드, 상세, 로그, 설정 화면.
- `assets/placeholder.png` : 오프라인 데모 이미지.

## API 연동 규칙
- 베이스 URL 예: `http://<PI_IP>:8000`
- 목록: `GET /records?limit=100&since=<ISO8601>` (since는 선택)
- 응답 필드 허용치:
  - `id`
  - `image_url` (상대 `/images/...` 또는 절대 URL)
  - `cell_row` or `row`
  - `cell_col` or `col`
  - `cell_id` (없으면 row/col로 계산)
  - `created_at` or `timestamp`
- 이미지: 상대 경로면 `baseUrl + image_url`

## UX 요약
- AppBar: Tank Monitor (Refresh, Settings)
- 본문: 연결 상태 → 격자 카드(2x3, 제곱 비율) → 업데이트 시각/범례
- 하단 버튼: Simulate Event / View Event Log
- 상세 화면: 큰 이미지 + ID + 시간 + 위치
- 로그 화면: 리스트 → 상세 이동
- 설정 화면: URL 입력/저장, 연결 상태 칩

## 오프라인/데모 체크리스트
- 서버 URL 비어 있으면 데모 모드로 동작(폴링 중단).
- 시뮬레이션 이벤트가 격자/로그/상세에 동일하게 반영되어야 함.

