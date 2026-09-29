import os
import time
import torch

if not torch.cuda.is_available():
    raise RuntimeError("CUDA is not available")

device = torch.device("cuda:0")
props = torch.cuda.get_device_properties(device)

duration = int(os.environ.get("STRESS_SECONDS", "60"))

print("=== SUSTAINED CUDA COMPUTE TEST ===")
print("GPU:", props.name)
print(f"VRAM: {props.total_memory / 1024**3:.2f} GiB")
print(f"Duration: {duration} seconds")

# Large enough to keep the GPU busy without consuming excessive VRAM.
size = 8192

print(f"Matrix size: {size} x {size}")
print("\nAllocating matrices...")

a = torch.randn((size, size), dtype=torch.float32, device=device)
b = torch.randn((size, size), dtype=torch.float32, device=device)

# Warm up CUDA before starting the timer.
print("Warming up...")
for _ in range(3):
    c = torch.mm(a, b)

torch.cuda.synchronize()

print("Starting sustained compute...")

start = time.monotonic()
iterations = 0

while True:
    c = torch.mm(a, b)
    iterations += 1

    # Synchronize periodically so errors cannot remain hidden
    # in CUDA's asynchronous execution queue.
    if iterations % 10 == 0:
        torch.cuda.synchronize()

    if time.monotonic() - start >= duration:
        break

torch.cuda.synchronize()

elapsed = time.monotonic() - start

print("\n=== RESULTS ===")
print(f"Elapsed: {elapsed:.1f} seconds")
print(f"Iterations: {iterations}")
print(f"Iterations/sec: {iterations / elapsed:.2f}")
print("Result finite:", torch.isfinite(c).all().item())

if not torch.isfinite(c).all():
    raise RuntimeError("GPU produced non-finite results")

print("\nPASS: sustained CUDA compute test completed successfully")
