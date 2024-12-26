# Use Python base image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install required Python packages
RUN pip install requests

# Copy the Python script into the container
COPY count_string_in_api_response.py .

# Command to run the Python script
CMD ["python", "count_string_in_api_response.py"]

