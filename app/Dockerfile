# Use lightweight Python image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app code
COPY . .

# Expose port for Flask
EXPOSE 5000

# Run app
CMD ["python", "app.py"]

# Health check
HEALTHCHECK CMD curl --fail http://localhost:5000/health || exit 1

