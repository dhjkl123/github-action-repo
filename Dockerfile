FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# 필수 패키지 최소 설치 (빌드 캐시 최적화)
RUN apt-get update && apt-get install -y --no-install-recommends tini && rm -rf /var/lib/apt/lists/*

# 비루트 유저
RUN useradd -m appuser
WORKDIR /app

# 의존성 먼저 복사 (캐시 히트용)
COPY requirements.txt .
RUN pip install -r requirements.txt

# 소스 복사
COPY app ./app

EXPOSE 8000
USER appuser

# 간단한 컨테이너 헬스체크용 스크립트
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request as r; r.urlopen('http://127.0.0.1:8000/health', timeout=2)"

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
