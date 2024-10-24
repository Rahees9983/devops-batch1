import requests
import json
import time
import logging
import threading
from flask import Flask, request, jsonify
from prometheus_client import Counter, start_http_server, make_wsgi_app, Histogram, Summary, Gauge
from werkzeug.middleware.dispatcher import DispatcherMiddleware

app = Flask(__name__)

# Global variables
monitoring_thread = None
stop_logging = False
app.wsgi_app =DispatcherMiddleware(app.wsgi_app, {'/metrics': make_wsgi_app()})
REQUESTS = Counter('http_requests_total','Total number of requests',labelnames=['path','method'])
LATENCY = Summary('request_latency_seconds','FlaskRequest Latency', labelnames=['path','method'])
IN_PROGRESS = Gauge('inprogress_requests','Total number of requests in progress',labelnames=['path','method'])

def before_request():
    request.start_time = time.time()

def after_request(response):
    request_latency = time.time() - request.start_time 
    LATENCY.labels(request.method,request.path).observe(request_latency)
    IN_PROGRESS.labels(request.method,request.path).dec()
    return response

# Define a Gauge metric for unique string count
UNIQUE_STRING_COUNT = Gauge('unique_string_count', 'Number of unique strings in the provided list')

# Global variable to store the current list of strings
current_strings = []

def update_unique_string_count(strings):
    """Update the unique string count metric based on the provided list."""
    unique_strings = set(strings)  # Use a set to find unique strings
    UNIQUE_STRING_COUNT.set(len(unique_strings))  # Set the metric value

@app.route('/count_unique_strings', methods=['POST'])
def count_unique_strings():
    global current_strings
    data = request.json
    if 'strings' not in data:
        return jsonify({'error': 'Strings list is required'}), 400

    if not isinstance(data['strings'], list):
        return jsonify({'error': 'Strings must be provided as a list'}), 400

    current_strings = data['strings']
    update_unique_string_count(current_strings)
    return jsonify({'message': f'Unique string count updated based on the provided list'}), 200

@app.get("/cars")
def get_cards():
    REQUESTS.labels('/cars','get').inc()
    #time.sleep(33)
    return ["toyota", "honda", "mazda" ,"lexus"]

@app.post("/cars")
def create_cars():
    REQUESTS.labels('/cars','post').inc()
    #time.sleep(23)
    return "Create Car"

@app.get("/boats")
def get_boats():
    REQUESTS.labels('/boats','get').inc()
    #time.sleep(65)
    return ["boat1","boat2","boat3"]

@app.post("/boats")
def create_boat():
    REQUESTS.labels('/boats','post').inc()
    return "Create Boat"

class JSONFormatter(logging.Formatter):
    """Custom JSON formatter for logging."""
    def format(self, record):
        log_record = {
            'timestamp': self.formatTime(record, self.datefmt),
            'level': record.levelname,
            'message': record.getMessage(),
            'name': record.name,
            'filename': record.filename,
            'lineno': record.lineno
        }
        return json.dumps(log_record)

def load_config(config_file):
    """Load configuration from a JSON file."""
    with open(config_file, 'r') as f:
        return json.load(f)

def check_website(url, content, env):
    """Check the website and log the result with environment information."""
    try:
        start_time = time.time()
        response = requests.get(url)
        end_time = time.time()

        if content in response.text:
            logging.info(json.dumps({
                'url': url,
                'status': 'SUCCESS',
                'response_time': f'{end_time - start_time:.2f}s',
                'env': env
            }))
        else:
            logging.warning(json.dumps({
                'url': url,
                'status': 'CONTENT MISMATCH',
                'env': env
            }))
    except requests.exceptions.RequestException as e:
        logging.error(json.dumps({
            'url': url,
            'status': 'CONNECTION ERROR',
            'error': str(e),
            'env': env
        }))

def setup_logging():
    """Set up logging configuration for both console and file."""
    # Create a logger
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)

    # File handler for writing logs to a file
    file_handler = logging.FileHandler('monitor.log')
    file_handler.setLevel(logging.INFO)
    file_formatter = logging.Formatter('%(asctime)s - %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
    file_handler.setFormatter(file_formatter)
    
    # Console handler for printing logs to the console
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    console_formatter = logging.Formatter('%(asctime)s - %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
    console_handler.setFormatter(console_formatter)

    # Add handlers to the logger
    logger.addHandler(file_handler)
    logger.addHandler(console_handler)


def enable_website_logs(config, interval):
    """Logging function to check websites periodically."""
    global stop_logging
    while not stop_logging:
        for site in config['sites']:
            check_website(site['url'], site['content'], site['env'])
        time.sleep(interval)

@app.route('/start_logging', methods=['POST'])
def start_monitoring():
    """Start Logging websites."""
    global monitoring_thread, stop_logging

    if monitoring_thread is not None and monitoring_thread.is_alive():
        return jsonify({'status': 'Logging is already running'}), 400

    config_file = request.json.get('config_file', 'config.json')
    interval = request.json.get('interval', 60)

    config = load_config(config_file)
    setup_logging()

    stop_logging = False
    monitoring_thread = threading.Thread(target=enable_website_logs, args=(config, interval))
    monitoring_thread.start()

    return jsonify({'status': 'Application Logging is started!!!!!!!!'}), 200

@app.route('/stop_logging', methods=['POST'])
def stop_monitoring_endpoint():
    """Stop Logging websites."""
    global stop_logging, monitoring_thread

    if monitoring_thread is None or not monitoring_thread.is_alive():
        return jsonify({'status': 'Application Logging is stopped....'}), 400

    stop_logging = True
    monitoring_thread.join()
    monitoring_thread = None 

    return jsonify({'status': 'Logging stopped'}), 200

@app.route('/logging_status', methods=['GET'])
def status():
    """Check the status of the Application Logging."""
    global monitoring_thread

    if monitoring_thread is not None and monitoring_thread.is_alive():
        return jsonify({'status': 'Logging is enabled'}), 200
    else:
        return jsonify({'status': 'Logging is not Enabled'}), 200

if __name__ == "__main__":
    app.before_request(before_request)
    app.after_request(after_request) 
    app.run(host='0.0.0.0', port=5000)
