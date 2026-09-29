#!/usr/bin/env bash
set -euo pipefail

echo "=== DATE ==="
date --iso-8601=seconds

echo
echo "=== HOST ==="
hostnamectl

echo
echo "=== NVIDIA-SMI ==="
nvidia-smi

echo
echo "=== NVIDIA-SMI GPU DETAILS ==="
nvidia-smi -q

echo
echo "=== PCI DEVICES ==="
lspci -nn | grep -iE 'nvidia|vga|3d'

echo
echo "=== NVIDIA DRIVER ==="
cat /proc/driver/nvidia/version

echo
echo "=== KERNEL ==="
uname -a
