#!/bin/bash
# Kawabel — Build Flutter web & deploy to Vercel
# Usage: ./deploy-web.sh [production|preview]
#
# Prerequisites:
#   - Flutter SDK installed
#   - Vercel CLI installed: npm i -g vercel
#   - Vercel project linked: vercel link
#
# Environment:
#   API_URL — Backend server URL (default: https://kawabel-api.railway.app)

set -e

MODE="${1:-preview}"
API_URL="${API_URL:-https://kawabel-api.railway.app}"

echo "Building Kawabel Flutter web app..."
echo "  API_URL = $API_URL"
echo "  Mode    = $MODE"
echo ""

# Build Flutter web
flutter build web --release --dart-define=API_URL="$API_URL"

echo ""
echo "Flutter web built -> build/web/"
echo ""

# Deploy to Vercel
if [ "$MODE" = "production" ]; then
  echo "Deploying to Vercel (production)..."
  vercel --prod
else
  echo "Deploying to Vercel (preview)..."
  vercel
fi

echo ""
echo "Done! Student app deployed to Vercel."
echo "Server (API) should be deployed separately to Railway/Render."
