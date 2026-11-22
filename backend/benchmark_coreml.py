
import time
import torch
import coremltools as ct
import numpy as np

MODEL_PATH = "analysis_reports/coreml/U_TALK_WavLM.mlpackage"

# Create a reproducible 3-second audio-shaped input
np.random.seed(42)
audio = np.random.randn(1, 48000).astype(np.float32)

# Measure model loading
print("Loading Core ML model...")
load_start = time.perf_counter()

model = ct.models.MLModel(
    MODEL_PATH,
    compute_units=ct.ComputeUnit.ALL
)

load_time = time.perf_counter() - load_start

# Warm-up
print("Warming up...")
for _ in range(5):
    model.predict({"audio": audio})

# Benchmark
print("Running 30 inference iterations...")
times = []

for _ in range(30):
    start = time.perf_counter()
    model.predict({"audio": audio})
    elapsed = time.perf_counter() - start
    times.append(elapsed)

times = np.array(times)

avg = np.mean(times)
median = np.median(times)
fastest = np.min(times)
slowest = np.max(times)

# Results
print("\n=== CORE ML BENCHMARK ===")
print("Compute units: ALL")
print("Input duration: 3 seconds")
print("Model loading time: {:.4f} seconds".format(load_time))
print("Average inference: {:.4f} seconds".format(avg))
print("Median inference: {:.4f} seconds".format(median))
print("Fastest inference: {:.4f} seconds".format(fastest))
print("Slowest inference: {:.4f} seconds".format(slowest))
print("Real-time factor: {:.2f}x".format(3 / avg))
