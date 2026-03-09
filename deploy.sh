#!/bin/bash
# Kawabel — Build & Deploy
# Usage: ./deploy.sh

set -e

echo "🦉 Building Kawabel..."

# 1. Build Flutter web app
echo "📱 Building Flutter web app..."
API_URL="${API_URL:-https://your-server.railway.app}"
flutter build web --dart-define=API_URL=$API_URL --no-wasm-dry-run

echo "✅ Flutter web built → build/web/"
echo ""

# 2. Install server dependencies
echo "📡 Installing server dependencies..."
cd server && npm ci --production && cd ..

echo ""
echo "🎉 Build complete!"
echo ""
echo "To deploy:"
echo ""
echo "  1. Flutter web -> Vercel (static):"
echo "     chmod +x deploy-web.sh"
echo "     API_URL=https://kawabel-api.railway.app ./deploy-web.sh production"
echo "     Or: vercel --prod (after building)"
echo ""
echo "  2. Server -> Railway/Render (Node.js + SQLite):"
echo "     - Push server/ folder"
echo "     - Set env vars: OPENAI_API_KEY, FONNTE_TOKEN (optional)"
echo "     - Server runs on port 3001"
echo ""
echo "  3. Admin dashboard:"
echo "     - Auto-served at /admin on the server"
echo ""
echo "  Teacher dashboard: https://kawabel-api.railway.app/admin"
echo "  Student app: https://kawabel.vercel.app"
