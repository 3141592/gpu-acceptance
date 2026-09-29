import os
import torch

if not torch.cuda.is_available():
    raise RuntimeError("CUDA is not available")

device = torch.device("cuda:0")
props = torch.cuda.get_device_properties(device)

fraction = float(os.environ.get("VRAM_FRACTION", "0.50"))
total = props.total_memory

print("=== VRAM INTEGRITY TEST ===")
print("GPU:", props.name)
print(f"Total VRAM: {total / 1024**3:.2f} GiB")
print(f"Requested fraction: {fraction:.0%}")

# Leave PyTorch/desktop/headroom rather than attempting to allocate
# every byte reported by the card.
free_memory, total_memory = torch.cuda.mem_get_info()

print(f"Free VRAM before test: {free_memory / 1024**3:.2f} GiB")
target_bytes = int(free_memory * fraction)

# int32 = 4 bytes per element
elements = target_bytes // 4

print(f"Target allocation: {target_bytes / 1024**3:.2f} GiB")
print(f"Elements: {elements:,}")

print("\nAllocating VRAM...")
data = torch.empty(elements, dtype=torch.int32, device=device)

patterns = [
    0x00000000,
    0xFFFFFFFF,
    0xAAAAAAAA,
    0x55555555,
]

chunk_elements = 16 * 1024 * 1024

for pattern in patterns:
    # Convert unsigned 32-bit pattern to signed int32 representation.
    signed_pattern = pattern if pattern < 0x80000000 else pattern - 0x100000000

    print(f"\nWriting pattern 0x{pattern:08X}...")
    data.fill_(signed_pattern)
    torch.cuda.synchronize()

    print("Verifying...")
    errors = 0

    for start in range(0, elements, chunk_elements):
        end = min(start + chunk_elements, elements)
        errors += torch.count_nonzero(
            data[start:end] != signed_pattern
        ).item()

    print(f"Errors: {errors:,}")

    if errors:
        raise RuntimeError(
            f"VRAM verification failed for pattern 0x{pattern:08X}: "
            f"{errors} incorrect elements"
        )

print("\nWriting address-dependent pattern...")

chunk_elements = 16 * 1024 * 1024

for start in range(0, elements, chunk_elements):
    end = min(start + chunk_elements, elements)

    values = torch.arange(
        start,
        end,
        dtype=torch.int64,
        device=device,
    )

    data[start:end] = values.to(torch.int32)

torch.cuda.synchronize()

print("Verifying address-dependent pattern...")

errors = 0

for start in range(0, elements, chunk_elements):
    end = min(start + chunk_elements, elements)

    expected = torch.arange(
        start,
        end,
        dtype=torch.int64,
        device=device,
    ).to(torch.int32)

    errors += torch.count_nonzero(
        data[start:end] != expected
    ).item()

torch.cuda.synchronize()

print(f"Errors: {errors}")

if errors:
    raise RuntimeError(
        f"VRAM address-dependent pattern failed with {errors} errors"
    )

del data
torch.cuda.empty_cache()

print("\nPASS: VRAM integrity test completed successfully")
