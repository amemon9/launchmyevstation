# Use an official Python runtime as a parent image.
# Make sure to use a Python version compatible with your dependencies.
FROM python:3.10-slim

# Set environment variables to prevent Python from writing .pyc files to disc
# and to keep Python from buffering stdout and stderr.
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set the working directory in the container.
WORKDIR /app

# Copy the requirements file and install dependencies.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code into the container.
COPY ./mcp_evstation_app /app/mcp_evstation_app

# Run the application. Cloud Run will set the PORT environment variable.
CMD ["python", "-m", "mcp_evstation_app.main"]