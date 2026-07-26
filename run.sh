#!/usr/bin/env bash
# Render the whole site: rebuild the CV and Resume PDFs (Typst) and the HTML
# pages (Quarto). Outputs land in docs/ for GitHub Pages and in files/ for
# the embedded PDFs.
#
# Usage:
#   ./render.sh            # full build (PDFs + site)
#   ./render.sh pdfs       # PDFs only (fast — skips Quarto)
#   ./render.sh site       # site only (skips Typst, reuses existing PDFs)
#   ./render.sh preview    # rebuild + start local preview at http://localhost:4040

set -euo pipefail
cd "$(dirname "$0")"

target="${1:-all}"

case "$target" in
  pdfs)
    ./cv/build-pdfs.sh
    ;;
  site)
    quarto render
    ;;
  all)
    quarto render
    ;;
  preview)
    quarto preview --port 4040
    ;;
  *)
    echo "Usage: $0 [all|pdfs|site|preview]" >&2
    exit 1
    ;;
esac
