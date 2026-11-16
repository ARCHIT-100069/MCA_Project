#!/usr/bin/env bash
# build_pdf.sh -- print the IEEE-style HTML report to PDF with headless Chrome
# Owner: Phalak Sharma
set -euo pipefail
cd "$(dirname "$0")"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
"$CHROME" --headless=new --disable-gpu --no-pdf-header-footer \
    --print-to-pdf="$PWD/phase1_report.pdf" "file://$PWD/phase1_report.html" 2>/dev/null
echo "wrote docs/report/phase1_report.pdf"
