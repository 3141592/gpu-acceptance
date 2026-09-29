import csv
import sys

if len(sys.argv) != 2:
    print(f"Usage: {sys.argv[0]} <telemetry.csv>")
    sys.exit(1)

filename = sys.argv[1]

with open(filename, newline="") as f:
    rows = list(csv.DictReader(f, skipinitialspace=True))

if not rows:
    raise RuntimeError("No telemetry samples found")

def number(value):
    value = value.strip()
    for suffix in (" %", " W", " MHz"):
        value = value.removesuffix(suffix)
    return float(value)

temps = [number(r["temperature.gpu"]) for r in rows]
utils = [number(r["utilization.gpu [%]"]) for r in rows]
powers = [number(r["power.draw [W]"]) for r in rows]
fans = [number(r["fan.speed [%]"]) for r in rows]
clocks = [number(r["clocks.current.graphics [MHz]"]) for r in rows]

thermal_sw = [
    r for r in rows
    if r["clocks_event_reasons.sw_thermal_slowdown"].strip() == "Active"
]

thermal_hw = [
    r for r in rows
    if r["clocks_event_reasons.hw_thermal_slowdown"].strip() == "Active"
]

power_cap = [
    r for r in rows
    if r["clocks_event_reasons.sw_power_cap"].strip() == "Active"
]

loaded = [
    r for r in rows
    if number(r["utilization.gpu [%]"]) >= 90
]

print("=== GPU TELEMETRY SUMMARY ===")
print(f"Samples: {len(rows)}")
print(f"Samples >=90% GPU utilization: {len(loaded)}")

print()
print(f"Peak GPU temperature: {max(temps):.0f} C")
print(f"Peak fan speed:       {max(fans):.0f} %")
print(f"Peak power draw:      {max(powers):.2f} W")
print(f"Peak graphics clock:  {max(clocks):.0f} MHz")
print(f"Peak GPU utilization: {max(utils):.0f} %")

print()
print(f"Power-cap samples:             {len(power_cap)}")
print(f"SW thermal-slowdown samples:   {len(thermal_sw)}")
print(f"HW thermal-slowdown samples:   {len(thermal_hw)}")

if thermal_sw or thermal_hw:
    print("\nFAIL: thermal slowdown was detected")
    sys.exit(2)

if not loaded:
    print("\nWARNING: GPU never reached 90% utilization")
    sys.exit(3)

print("\nPASS: no thermal slowdown detected under sustained GPU load")
