# Stage 1: Build the Flutter Web App
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app
COPY coder_app/ ./coder_app/
WORKDIR /app/coder_app
# Resolve dependencies and build Web release
RUN flutter pub get
RUN flutter build web --release

# Stage 2: Serve with Python FastAPI
FROM python:3.11-slim
WORKDIR /app

# Install compilation tools for Python ML packages (FAISS, etc.)
RUN apt-get update && apt-get install -y build-essential curl gcc && rm -rf /var/lib/apt/lists/*

# Copy backend requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend source
COPY agent.py api.py ./

# Copy compiled Flutter web app from Stage 1 into the backend directory
COPY --from=build /app/coder_app/build/web ./coder_app/build/web

# Expose port (Render/Heroku/Railway sets standard PORT environment variable)
ENV PORT=8000
EXPOSE $PORT

# Start the unified backend & frontend server
CMD ["sh", "-c", "uvicorn api:app --host 0.0.0.0 --port $PORT"]
