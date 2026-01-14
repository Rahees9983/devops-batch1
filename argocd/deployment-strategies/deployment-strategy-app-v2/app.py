from flask import Flask
import socket

app = Flask(__name__)

@app.route('/')
def hello():
    hostname = socket.gethostname()
    html = '''</div><!doctype html>
<title>Hello from Flask</title>
<body style="background: #16a085;"></body>
<div style="color: #e4e4e4;
    text-align:  center;
    height: 90px;
    vertical-align:  middle;">

  <h1>Hello from ''' + hostname + '''!</h1>



  <h2>
    Application Version: v2
  </h2>'''
    return html

@app.route('/health')
def health():
    return 'OK', 200

@app.route('/ready')
def ready():
    return 'OK', 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
