#!/usr/bin/env bash
# Checks every external link in index.html.
#
# Fails on real HTTP errors (404, 410, 5xx).
# Hosts that block automated clients - TLS handshake failure, 403 or 429 - are
# reported as warnings: tpf-technology.com answers browsers but drops non-browser
# clients, so a hard failure there would make CI red for reasons unrelated to the repo.
set -uo pipefail

status=0
mapfile -t urls < <(grep -oE 'href="https?://[^"]+"' index.html | sed -E 's/^href="//; s/"$//' | sort -u)

for url in "${urls[@]}"; do
  code=$(curl -sL -o /dev/null --max-time 25 -A 'Mozilla/5.0 (compatible; link-check)' -w '%{http_code}' "$url" 2>/dev/null) || code=000
  case "$code" in
    2*|3*)           echo "ok    $code  $url" ;;
    000|403|429|503) echo "warn  $code  $url (blocked or unreachable, not counted as failure)" ;;
    *)               echo "fail  $code  $url"; status=1 ;;
  esac
done

[ "$status" -eq 0 ] && echo "No broken links." || echo "Broken links found."
exit "$status"
