#!/usr/bin/env bash
set -euo pipefail
TEST_START="$(date --iso-8601=seconds)"

if [[ $# -lt 2 || $# -gt 3 ]]; then
    echo "Usage: $0 <config-file> <test-script> [--monitor]"
    exit 1
fi

CONFIG="$1"
TEST="$2"
MONITOR="${3:-}"

source "$CONFIG"

export GPU_LABEL
export VRAM_FRACTION
export STRESS_SECONDS

RUN_ID="${GPU_LABEL}-$(date +%Y%m%d-%H%M%S)"
RESULT_DIR="results/${RUN_ID}"
mkdir -p "$RESULT_DIR"

TEST_NAME="$(basename "$TEST")"
OUTPUT="${RESULT_DIR}/${TEST_NAME%.*}.txt"
TELEMETRY="${RESULT_DIR}/telemetry.csv"

echo "GPU:     $GPU_LABEL"
echo "Test:    $TEST"
echo "Results: $OUTPUT"

MONITOR_PID=""

if [[ "$MONITOR" == "--monitor" ]]; then
    SUMMARY="${RESULT_DIR}/telemetry-summary.txt"

    echo
    echo "Analyzing telemetry..."

    python scripts/analyze-telemetry.py "$TELEMETRY" \
        2>&1 | tee "$SUMMARY"
fi

if [[ "$MONITOR" == "--monitor" ]]; then
    XID_OUTPUT="${RESULT_DIR}/xid-check.txt"

    echo
    echo "Checking NVIDIA kernel errors..."

    ./scripts/06-check-xid.sh "$TEST_START" \
        2>&1 | tee "$XID_OUTPUT"
fi

cleanup() {
    if [[ -n "$MONITOR_PID" ]]; then
        kill "$MONITOR_PID" 2>/dev/null || true
        wait "$MONITOR_PID" 2>/dev/null || true
    fi
}

trap cleanup EXIT INT TERM

if [[ "$MONITOR" == "--monitor" ]]; then
    echo "Monitor: $TELEMETRY"
    ./scripts/05-monitor.sh > "$TELEMETRY" &
    MONITOR_PID=$!

    # Give nvidia-smi time to record the initial idle sample.
    sleep 2
fi

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

cleanup
MONITOR_PID=""

echo
echo "Results saved to: $RESULT_DIR"
