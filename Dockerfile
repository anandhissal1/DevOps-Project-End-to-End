# Stage 1: build
FROM python:3.11-slim as build
WORKDIR /app
COPY app/requirements.txt ./
RUN pip install --upgrade pip && pip wheel -r requirements.txt --wheel-dir=/wheels

# Stage 2: runtime
FROM python:3.11-slim

# Install curl for healthcheck
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd --no-create-home --uid 10001 appuser

WORKDIR /app

# Copy wheels and app
COPY --from=build /wheels /wheels
COPY app /app

# Install dependencies from wheels
RUN pip install --no-cache-dir --no-index --find-links=/wheels -r requirements.txt

# Drop privileges
USER appuser

EXPOSE 8080

# Healthcheck (now curl exists)
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app", "--workers", "2"]

