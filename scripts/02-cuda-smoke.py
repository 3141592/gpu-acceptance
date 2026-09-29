import sys
import torch

print("=== PYTHON / PYTORCH ===")
print("Python:", sys.version.split()[0])
print("PyTorch:", torch.__version__)
print("PyTorch CUDA:", torch.version.cuda)

print("\n=== CUDA ===")
print("CUDA available:", torch.cuda.is_available())

if not torch.cuda.is_available():
    raise RuntimeError("CUDA is not available")

device = torch.device("cuda:0")
props = torch.cuda.get_device_properties(device)

print("GPU:", props.name)
print("VRAM:", f"{props.total_memory / 1024**3:.2f} GiB")
print("Compute capability:", f"{props.major}.{props.minor}")

print("\n=== BASIC CUDA COMPUTE ===")

a = torch.randn((4096, 4096), device=device)
b = torch.randn((4096, 4096), device=device)

c = a @ b
torch.cuda.synchronize()

print("Matrix multiply completed")
print("Result shape:", tuple(c.shape))
print("Result finite:", torch.isfinite(c).all().item())

if not torch.isfinite(c).all():
    raise RuntimeError("CUDA computation produced non-finite values")

print("\nPASS: CUDA smoke test completed successfully")
