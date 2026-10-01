#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <config-file>"
    exit 1
fi

CONFIG="$1"

source "$CONFIG"

export GPU_LABEL
export VRAM_FRACTION
export STRESS_SECONDS

TEST_START="$(date --iso-8601=seconds)"
RUN_ID="${GPU_LABEL}-$(date +%Y%m%d-%H%M%S)"
RESULT_DIR="results/${RUN_ID}"

mkdir -p "$RESULT_DIR"

echo "=== GPU ACCEPTANCE TEST SUITE ==="
echo "GPU:       $GPU_LABEL"
echo "Started:   $TEST_START"
echo "Results:   $RESULT_DIR"
echo

echo "=== STEP 1: SYSTEM INFORMATION ==="

./scripts/01-system-info.sh \
    2>&1 | tee "${RESULT_DIR}/system-info.txt"

echo
echo "System information complete."

echo
echo "=== STEP 2: CUDA SMOKE TEST ==="

python scripts/02-cuda-smoke.py \
    2>&1 | tee "${RESULT_DIR}/cuda-smoke.txt"

echo
echo "CUDA smoke test complete."

echo
echo "=== STEP 3: VRAM INTEGRITY TEST ==="

python scripts/03-vram-test.py \
    2>&1 | tee "${RESULT_DIR}/vram-test.txt"

echo
echo "VRAM integrity test complete."

echo
echo "=== STEP 4: SUSTAINED COMPUTE STRESS ==="

TELEMETRY="${RESULT_DIR}/telemetry.csv"

./scripts/05-monitor.sh > "$TELEMETRY" &
MONITOR_PID=$!

cleanup_monitor() {
    if [[ -n "${MONITOR_PID:-}" ]]; then
        kill "$MONITOR_PID" 2>/dev/null || true
        wait "$MONITOR_PID" 2>/dev/null || true
    fi
}

trap cleanup_monitor EXIT INT TERM

# Capture an idle sample before starting the workload.
sleep 2

python scripts/04-compute-stress.py \
    2>&1 | tee "${RESULT_DIR}/compute-stress.txt"

cleanup_monitor
MONITOR_PID=""

echo
echo "Compute stress test complete."

echo
echo "=== STEP 5: TELEMETRY ANALYSIS ==="

python scripts/analyze-telemetry.py "$TELEMETRY" \
    2>&1 | tee "${RESULT_DIR}/telemetry-summary.txt"

echo
echo "Telemetry analysis complete."

echo
echo "=== STEP 6: NVIDIA KERNEL ERROR CHECK ==="

./scripts/06-check-xid.sh "$TEST_START" \
    2>&1 | tee "${RESULT_DIR}/xid-check.txt"

echo
echo "Kernel error check complete."

echo
echo "=== GPU ACCEPTANCE TEST SUITE COMPLETE ==="
echo "Results: $RESULT_DIR"
