import os
# from flask import Flask
from flask import render_template
import socket
import random
from flask import Flask, request, redirect, url_for, send_from_directory
app = Flask(__name__)

app.config['UPLOAD_FOLDER'] = os.getenv('UPLOAD_FOLDER', '/rahees-uploaded-files')
#/rahees-uploaded-files is the folder inside the container (it will be created if it does not exists)
# to pass this value inside docker command is use -e option eg. docker run --name akki -e UPLOAD_FOLDER="/usr/src/app" ur-img-name

app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16 MB limit

if not os.path.exists(app.config['UPLOAD_FOLDER']):
    os.makedirs(app.config['UPLOAD_FOLDER'])

color_codes = {
    "red": "#e74c3c",
    "green": "#16a085",
    "blue": "#2980b9",
    "blue2": "#30336b",
    "pink": "#be2edd",
    "darkblue": "#130f40"
}

color = os.environ.get('APP_COLOR') or random.choice(["red","green","blue","blue2","darkblue","pink"])

@app.route("/")
def main():
    #return 'Hello'
    print(color)
    return render_template('hello.html', name=socket.gethostname(), color=color_codes[color])

@app.route('/color/<new_color>')
def new_color(new_color):
    return render_template('hello.html', name=socket.gethostname(), color=color_codes[new_color])

@app.route('/read_file')
def read_file():
    f = open("/data/testfile.txt")
    contents = f.read()
    return render_template('hello.html', name=socket.gethostname(), contents=contents, color=color_codes[color])

@app.route('/upload-title')
def index():
    return render_template('fill-form.html')

    # return '''
    # <!doctype html>
    # <title>Upload a File</title>
    # <h1>Upload a File</h1>
    # <form action="/upload" method=post enctype=multipart/form-data>
    #   <input type=file name=file>
    #   <input type=submit value=Upload>
    # </form>
    # '''

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return redirect(request.url)
    file = request.files['file']
    if file.filename == '':
        return redirect(request.url)
    if file:
        file.save(os.path.join(app.config['UPLOAD_FOLDER'], file.filename))
        # return f'File uploaded successfully: {file.filename}'
        return render_template('sucessful-upload.html', uploaded_filename=file.filename)

@app.route('/files/<filename>')
def uploaded_file(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port="8080")
