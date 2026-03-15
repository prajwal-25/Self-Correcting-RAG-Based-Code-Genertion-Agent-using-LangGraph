#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────────
# start.sh  –  Starts the FastAPI backend + Flutter web dev server
# ────────────────────────────────────────────────────────────────────
# Usage:
#   bash start.sh
#
# Requirements:
#   • Python 3.11+ with packages from requirements.txt installed
#   • MISTRAL_API_KEY set in environment or in a .env file
#   • Flutter SDK installed
# ────────────────────────────────────────────────────────────────────

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🚀 Starting Coder Agent..."

# 1. Load env file if present
if [ -f "$SCRIPT_DIR/.env" ]; then
  export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
  echo "✅ Loaded .env"
fi

# 2. Start FastAPI backend in background
echo "🐍 Starting FastAPI backend on http://localhost:8000 ..."
uvicorn api:app --reload --port 8000 --host 0.0.0.0 &
BACKEND_PID=$!

# 3. Start Flutter web dev server
echo "🦋 Starting Flutter web on http://localhost:5200 ..."
cd "$SCRIPT_DIR/coder_app"
flutter run -d web-server --web-port 5200 --web-hostname 0.0.0.0

# Cleanup on exit
trap "kill $BACKEND_PID" EXIT
