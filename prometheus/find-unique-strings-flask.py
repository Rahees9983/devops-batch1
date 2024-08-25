from flask import Flask, request
from prometheus_client import Counter, start_http_server, make_wsgi_app, Histogram, Summary, Gauge
from werkzeug.middleware.dispatcher import DispatcherMiddleware
import time

app = Flask(__name__)
app.wsgi_app =DispatcherMiddleware(app.wsgi_app, {'/metrics': make_wsgi_app()})
REQUESTS = Counter('http_requests_total','Total number of requests',labelnames=['path','method'])
#LATENCY = Histogram('request_latency_seconds','Request Latency', labelnames=['path','method'])
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

@app.route('/update_strings', methods=['POST'])
def update_strings():
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

if __name__ == '__main__':  
    start_http_server(8000)
    app.before_request(before_request)
    app.after_request(after_request)    
    app.run(host="0.0.0.0",port=5000)
