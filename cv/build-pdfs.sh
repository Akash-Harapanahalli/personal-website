#!/usr/bin/env bash
# Render CV and Resume PDFs from cv.typ and resume.typ (which both pull data
# from ../_data/cv.yml). Copy the outputs to files/ so the site's links resolve.
# Invoked as a Quarto pre-render hook (see _quarto.yml).

set -euo pipefail

# Resolve project root (this script lives at <root>/cv/build-pdfs.sh).
root="$(cd "$(dirname "$0")/.." && pwd)"

# Prefer a system `typst`, fall back to the one Quarto bundles.
if command -v typst >/dev/null 2>&1; then
  typst_bin=typst
elif [ -x /opt/quarto/bin/tools/x86_64/typst ]; then
  typst_bin=/opt/quarto/bin/tools/x86_64/typst
else
  echo "build-pdfs.sh: typst not found (install typst or run via quarto)" >&2
  exit 1
fi

cd "$root"
mkdir -p files
"$typst_bin" compile --root . cv/cv.typ     files/AkashHarapanahalliCV.pdf
"$typst_bin" compile --root . cv/resume.typ files/AkashHarapanahalliResume.pdf

echo "build-pdfs.sh: rebuilt CV + Resume PDFs into files/"
