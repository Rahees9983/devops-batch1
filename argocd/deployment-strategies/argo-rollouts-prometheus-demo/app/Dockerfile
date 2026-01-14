FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 8080

# Build arguments for different scenarios
ARG APP_VERSION=v1
ARG ERROR_RATE=0
ARG LATENCY=0

# Set environment variables from build args
ENV APP_VERSION=${APP_VERSION}
ENV ERROR_RATE=${ERROR_RATE}
ENV LATENCY=${LATENCY}

CMD ["python", "app.py"]
