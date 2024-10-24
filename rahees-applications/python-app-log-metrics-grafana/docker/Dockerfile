# Use the official Python image from the Docker Hub
FROM python:3.12-slim

# Set the working directory inside the Docker container
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Install required packages
RUN pip install --no-cache-dir -r requirements.txt

# Expose the port on which your Flask app will run
EXPOSE 5000

# Set the environment variable to run the Flask app in development mode
ENV FLASK_APP=metrics-logs-python-app.py
ENV FLASK_RUN_HOST=0.0.0.0
ENV FLASK_ENV=development

# Command to run the Flask app
CMD ["flask", "run", "--host=0.0.0.0"]
