# Raspberry Pi + FastAPI 백엔드 명세

## 목적
- ESP32-CAM(또는 라즈베리파이 자체)에서 촬영한 이미지와 수거 위치(cell_row, cell_col)를 수신하고 저장.
- Flutter 앱이 `/records`로 목록을 받아 2x3 격자에 표시하고 이미지를 조회하도록 한다.

## 요구 API
- `POST /upload`
  - form-data: `image`(파일), `cell_row`(int), `cell_col`(int)
  - 응답: `id`, `image_url`, `cell_row`, `cell_col`, `created_at`
- `GET /records`
  - 쿼리: `limit`(기본 200), `since`(ISO8601, 옵션)
  - 응답: 최신순 배열. 각 항목은 `id`, `image_url`, `cell_row`, `cell_col`, `created_at`
- 정적 파일: `/images/{filename}` (이미지 서빙)

## 데이터베이스
- SQLite (data.db)
- 테이블: `records`
  - `id INTEGER PRIMARY KEY AUTOINCREMENT`
  - `filename TEXT NOT NULL`
  - `cell_row INTEGER NOT NULL`
  - `cell_col INTEGER NOT NULL`
  - `created_at TEXT NOT NULL` (ISO8601)

## 폴더 구조(권장)
```
project_spec/backend/
├─ main.py               # FastAPI 앱
├─ requirements.txt      # 의존성
├─ images/               # 업로드 이미지 저장 경로(자동 생성)
└─ data.db               # SQLite (실행 시 생성)
```

## 실행 방법 (라즈베리파이)
```bash
sudo apt update && sudo apt install -y python3-pip python3-venv
cd project_spec/backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000
```
- 같은 와이파이에서 Flutter 앱 베이스 URL 예: `http://<라즈베리파이_IP>:8000`
- IP 확인: `hostname -I`

## FastAPI 코드 동작 요약
- `/upload`: 파일을 `images/`에 저장, DB에 row/col/timestamp 기록, 상대 `image_url` 반환.
- `/records`: `limit`, `since` 조건으로 최신순 조회, `/images/<filename>` 상대 경로 반환.
- `/images`: StaticFiles로 이미지 제공.

## 테스트 예시
```bash
curl -X POST "http://<PI_IP>:8000/upload" \
  -F "image=@test.jpg" \
  -F "cell_row=0" \
  -F "cell_col=2"

curl "http://<PI_IP>:8000/records?limit=50"
```

## 주의/확장 포인트
- 네트워크: 동일 무선망 권장, 안정성 위해 유선 LAN 가능.
- 보안: 해커톤 데모 기준 인증 없음. 공개망 사용 시 토큰/서명 추가 권장.
- 실시간: 필요 시 SSE/WebSocket 추가 가능(현재는 폴링 전제).
- AI/분석: 저장된 이미지를 후처리(분류/집계)하는 모듈을 분리해 추가 가능.

