#!/usr/bin/env bash
set -euo pipefail

INTERVAL="${1:-1}"

nvidia-smi \
  --query-gpu=timestamp,name,utilization.gpu,utilization.memory,temperature.gpu,fan.speed,power.draw,power.limit,clocks.current.graphics,clocks.current.memory,pstate,pcie.link.gen.current,pcie.link.width.current,clocks_event_reasons.sw_power_cap,clocks_event_reasons.sw_thermal_slowdown,clocks_event_reasons.hw_thermal_slowdown \
  --format=csv \
  --loop="$INTERVAL"
