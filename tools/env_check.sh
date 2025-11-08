#!/usr/bin/env bash
set -euo pipefail
echo "gcc: $(gcc --version | head -1)"
echo "cmake: $(cmake --version | head -1)"
echo "ninja: $(ninja --version)"
echo "python: $(python3 --version)"
if command -v nvidia-smi >/dev/null; then nvidia-smi -L; else echo "No NVIDIA GPU detected"; fi

