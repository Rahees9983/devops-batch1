# Dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY . /app

# Install Flask-RESTx, Flask, and PyMySQL for MySQL connectivity
RUN pip install --no-cache-dir flask-restx flask pymysql mysql-connector-python

EXPOSE 5000

ENV FLASK_APP=app.py

CMD ["python", "app.py"]

