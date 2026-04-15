#!/bin/bash

# Local Development Setup & Run Script
# This helps you run the app locally for testing

echo "🚀 Starting Local Development Environment"
echo ""

# Go to the project directory
cd /Users/white/Tech/ci-cd/hello-world-node

# Check if node_modules exist
if [ ! -d "node_modules" ]; then
  echo "📦 Installing dependencies..."
  npm install
  echo ""
fi

# Check if app.js exists
if [ ! -f "app.js" ]; then
  echo "❌ Error: app.js not found"
  exit 1
fi

# Start the application
echo "✅ Starting application on http://localhost:3000"
echo ""
echo "Press Ctrl+C to stop"
echo ""
npm start
