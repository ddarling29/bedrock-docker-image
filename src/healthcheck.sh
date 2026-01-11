#!/usr/bin/env bash
set -euo pipefail

# Adjust if your binary name differs
if pgrep -x "bedrock_server" >/dev/null; then
  echo -e "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nOK"
  exit 0
else
  echo -e "HTTP/1.1 503 Service Unavailable\r\nContent-Length: 3\r\n\r\nBAD"
  exit 1
fi
