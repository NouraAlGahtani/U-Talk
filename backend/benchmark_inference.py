
import time
import torch
import numpy as np
from pathlib import Path

from evaluate_sep28k_reviewed import StutteringClassifier, CHECKPOINT

DEVICE = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
SAMPLE_RATE = 16000
CLIP_SECONDS = 3
NUM_RUNS = 30
WARMUP_RUNS = 5

print(f"Device: {DEVICE}")

# Measure model loading
load_start = time.perf_counter()

model = StutteringClassifier().to(DEVICE)

checkpoint = torch.load(
    CHECKPOINT,
    map_location="cpu",
    weights_only=False
)
model.load_state_dict(checkpoint["model_state_dict"], strict=True)
model.eval()

if DEVICE.type == "mps":
    torch.mps.synchronize()

load_time = time.perf_counter() - load_start
print(f"Model loading time: {load_time:.3f} seconds")

# Prepare a 3-second test input
audio = np.random.randn(SAMPLE_RATE * CLIP_SECONDS).astype(np.float32)
input_tensor = torch.from_numpy(audio).unsqueeze(0).to(DEVICE)

# Warm-up
print(f"Running {WARMUP_RUNS} warm-up iterations...")

with torch.inference_mode():
    for _ in range(WARMUP_RUNS):
        _ = model(input_tensor)

if DEVICE.type == "mps":
    torch.mps.synchronize()

# Benchmark
times = []

print(f"Benchmarking {NUM_RUNS} iterations...")

with torch.inference_mode():
    for _ in range(NUM_RUNS):
        if DEVICE.type == "mps":
            torch.mps.synchronize()

        start = time.perf_counter()
        _ = model(input_tensor)

        if DEVICE.type == "mps":
            torch.mps.synchronize()

        times.append(time.perf_counter() - start)

times = np.array(times)

print("\n=== INFERENCE BENCHMARK ===")
print(f"Device: {DEVICE}")
print(f"Input duration: {CLIP_SECONDS} seconds")
print(f"Runs: {NUM_RUNS}")
print(f"Average inference: {times.mean():.4f} seconds")
print(f"Median inference: {np.median(times):.4f} seconds")
print(f"Fastest inference: {times.min():.4f} seconds")
print(f"Slowest inference: {times.max():.4f} seconds")
print(f"Real-time factor: {CLIP_SECONDS / times.mean():.2f}x")

if DEVICE.type == "mps":
    print(f"MPS allocated memory: {torch.mps.current_allocated_memory() / 1024**3:.2f} GB")

