#!/usr/bin/env bash
set -euo pipefail
URL="https://cloud.oracle.com/cloudshell"

# Try common chrome executables
if command -v google-chrome >/dev/null 2>&1; then
  google-chrome "$URL" &
  exit 0
fi
if command -v google-chrome-stable >/dev/null 2>&1; then
  google-chrome-stable "$URL" &
  exit 0
fi
if command -v chromium-browser >/dev/null 2>&1; then
  chromium-browser "$URL" &
  exit 0
fi
if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$URL" &
  exit 0
fi
# macOS
if command -v open >/dev/null 2>&1; then
  open -a "Google Chrome" "$URL" &
  exit 0
fi

echo "Could not find a Chrome executable. Please open the URL manually: $URL" >&2
exit 2
