#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <config-file> <test-script>"
    exit 1
fi

CONFIG="$1"
TEST="$2"

source "$CONFIG"
export GPU_LABEL
export VRAM_FRACTION
export STRESS_SECONDS

RUN_ID="${GPU_LABEL}-$(date +%Y%m%d-%H%M%S)"
RESULT_DIR="results/${RUN_ID}"
mkdir -p "$RESULT_DIR"

TEST_NAME="$(basename "$TEST")"
OUTPUT="${RESULT_DIR}/${TEST_NAME%.*}.txt"

echo "GPU:     $GPU_LABEL"
echo "Test:    $TEST"
echo "Results: $OUTPUT"
echo

case "$TEST" in
    *.py)
        python "$TEST" 2>&1 | tee "$OUTPUT"
        ;;
    *.sh)
        "$TEST" 2>&1 | tee "$OUTPUT"
        ;;
    *)
        echo "Unsupported test type: $TEST"
        exit 1
        ;;
esac

echo
echo "Results saved to: $OUTPUT"
