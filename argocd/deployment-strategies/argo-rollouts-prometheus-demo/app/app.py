from flask import Flask, jsonify, request
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
import random
import time
import os
import socket

app = Flask(__name__)

# Get configuration from environment
APP_VERSION = os.getenv('APP_VERSION', 'v1')
# Error rate: 0 = no errors, 0.5 = 50% errors, 1 = 100% errors
ERROR_RATE = float(os.getenv('ERROR_RATE', '0'))
# Latency in seconds to add (simulates slow responses)
LATENCY = float(os.getenv('LATENCY', '0'))

# Prometheus Metrics
REQUEST_COUNT = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status', 'version']
)

REQUEST_LATENCY = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency in seconds',
    ['method', 'endpoint', 'version'],
    buckets=[0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0]
)

ERROR_COUNT = Counter(
    'http_errors_total',
    'Total HTTP errors',
    ['method', 'endpoint', 'error_type', 'version']
)

SUCCESS_RATE = Gauge(
    'app_success_rate',
    'Current success rate of the application',
    ['version']
)

APP_INFO = Gauge(
    'app_info',
    'Application information',
    ['version', 'hostname']
)

# Set app info on startup
APP_INFO.labels(version=APP_VERSION, hostname=socket.gethostname()).set(1)

@app.before_request
def before_request():
    request.start_time = time.time()

@app.after_request
def after_request(response):
    latency = time.time() - request.start_time
    REQUEST_LATENCY.labels(
        method=request.method,
        endpoint=request.path,
        version=APP_VERSION
    ).observe(latency)
    return response

@app.route('/')
def home():
    # Simulate latency
    if LATENCY > 0:
        time.sleep(LATENCY)

    # Simulate errors based on ERROR_RATE
    if random.random() < ERROR_RATE:
        REQUEST_COUNT.labels(
            method='GET',
            endpoint='/',
            status='500',
            version=APP_VERSION
        ).inc()
        ERROR_COUNT.labels(
            method='GET',
            endpoint='/',
            error_type='internal_error',
            version=APP_VERSION
        ).inc()
        return jsonify({
            'status': 'error',
            'message': 'Internal Server Error',
            'version': APP_VERSION,
            'hostname': socket.gethostname()
        }), 500

    REQUEST_COUNT.labels(
        method='GET',
        endpoint='/',
        status='200',
        version=APP_VERSION
    ).inc()

    # Calculate and update success rate
    success_rate = 1 - ERROR_RATE
    SUCCESS_RATE.labels(version=APP_VERSION).set(success_rate)

    html = f'''<!DOCTYPE html>
<html>
<head>
    <title>Rollouts Demo App</title>
    <style>
        body {{
            background: {'#27ae60' if APP_VERSION == 'v1' else '#e74c3c' if ERROR_RATE > 0.3 else '#3498db'};
            color: white;
            font-family: Arial, sans-serif;
            text-align: center;
            padding: 50px;
        }}
        .container {{
            background: rgba(0,0,0,0.2);
            padding: 30px;
            border-radius: 10px;
            display: inline-block;
        }}
        .metric {{
            margin: 10px 0;
            padding: 10px;
            background: rgba(255,255,255,0.1);
            border-radius: 5px;
        }}
        .healthy {{ color: #2ecc71; }}
        .unhealthy {{ color: #e74c3c; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>Rollouts Demo Application</h1>
        <h2>Version: {APP_VERSION}</h2>
        <h3>Hostname: {socket.gethostname()}</h3>

        <div class="metric">
            <strong>Error Rate:</strong> {ERROR_RATE * 100}%
            <span class="{'unhealthy' if ERROR_RATE > 0.1 else 'healthy'}">
                {'⚠️ UNHEALTHY' if ERROR_RATE > 0.1 else '✅ HEALTHY'}
            </span>
        </div>

        <div class="metric">
            <strong>Simulated Latency:</strong> {LATENCY}s
        </div>

        <div class="metric">
            <strong>Success Rate:</strong> {(1 - ERROR_RATE) * 100}%
        </div>
    </div>
</body>
</html>'''
    return html

@app.route('/health')
def health():
    """Health check endpoint - always returns 200"""
    return jsonify({
        'status': 'healthy',
        'version': APP_VERSION
    }), 200

@app.route('/ready')
def ready():
    """Readiness check - fails if error rate is too high"""
    if ERROR_RATE > 0.5:
        return jsonify({
            'status': 'not ready',
            'reason': 'error rate too high',
            'error_rate': ERROR_RATE
        }), 503
    return jsonify({
        'status': 'ready',
        'version': APP_VERSION
    }), 200

@app.route('/api/data')
def api_data():
    """API endpoint that respects error rate"""
    # Simulate latency
    if LATENCY > 0:
        time.sleep(LATENCY)

    # Simulate errors
    if random.random() < ERROR_RATE:
        REQUEST_COUNT.labels(
            method='GET',
            endpoint='/api/data',
            status='500',
            version=APP_VERSION
        ).inc()
        ERROR_COUNT.labels(
            method='GET',
            endpoint='/api/data',
            error_type='internal_error',
            version=APP_VERSION
        ).inc()
        return jsonify({
            'error': 'Failed to fetch data',
            'version': APP_VERSION
        }), 500

    REQUEST_COUNT.labels(
        method='GET',
        endpoint='/api/data',
        status='200',
        version=APP_VERSION
    ).inc()

    return jsonify({
        'data': 'Sample data from API',
        'version': APP_VERSION,
        'hostname': socket.gethostname(),
        'timestamp': time.time()
    }), 200

@app.route('/metrics')
def metrics():
    """Prometheus metrics endpoint"""
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

if __name__ == '__main__':
    print(f"Starting app version {APP_VERSION}")
    print(f"Error rate: {ERROR_RATE * 100}%")
    print(f"Latency: {LATENCY}s")
    app.run(host='0.0.0.0', port=8080)
