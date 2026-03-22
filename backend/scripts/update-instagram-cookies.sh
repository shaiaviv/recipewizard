#!/usr/bin/env bash
# Usage: ./scripts/update-instagram-cookies.sh [path/to/cookies.txt]
# Updates the INSTAGRAM_COOKIES_B64 env var on Railway with your latest cookies.

set -e

COOKIES_FILE="${1:-./cookies.txt}"

if [ ! -f "$COOKIES_FILE" ]; then
  echo "Error: cookies file not found at '$COOKIES_FILE'"
  echo "Export cookies from your browser using 'Get cookies.txt LOCALLY' and try again."
  exit 1
fi

if ! command -v railway &>/dev/null; then
  echo "Error: Railway CLI not installed. Run: npm install -g @railway/cli"
  exit 1
fi

ENCODED=$(base64 < "$COOKIES_FILE")

echo "Uploading cookies to Railway..."
railway variables set INSTAGRAM_COOKIES_B64="$ENCODED"

echo "Done! Railway will redeploy with the new cookies."
