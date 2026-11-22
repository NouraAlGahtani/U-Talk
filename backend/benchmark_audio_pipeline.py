
import time
import soundfile as sf
import numpy as np
import torch
from scipy.signal import resample_poly
from math import gcd
from pathlib import Path

from evaluate_sep28k_reviewed import StutteringClassifier, CHECKPOINT

AUDIO_PATH = Path.home() / "Desktop/download/M_1064_47y0m_1.wav"
DEVICE = torch.device("mps" if torch.backends.mps.is_available() else "cpu")

# Load model
start = time.perf_counter()

model = StutteringClassifier().to(DEVICE)
checkpoint = torch.load(CHECKPOINT, map_location="cpu", weights_only=False)
model.load_state_dict(checkpoint["model_state_dict"], strict=True)
model.eval()

if DEVICE.type == "mps":
    torch.mps.synchronize()

print(f"Model loading: {time.perf_counter() - start:.3f}s")

# Load a real 3-second audio segment
audio, original_sr = sf.read(AUDIO_PATH)

if audio.ndim > 1:
    audio = audio.mean(axis=1)

audio = audio[:int(3 * original_sr)].astype(np.float32)

# Warm-up
with torch.inference_mode():
    dummy = torch.zeros(1, 48000, device=DEVICE)
    for _ in range(5):
        model(dummy)

if DEVICE.type == "mps":
    torch.mps.synchronize()

preprocessing_times = []
inference_times = []
total_times = []

for _ in range(30):
    total_start = time.perf_counter()

    # Resample to 16 kHz
    prep_start = time.perf_counter()

    divisor = gcd(original_sr, 16000)
    processed = resample_poly(
        audio,
        16000 // divisor,
        original_sr // divisor
    ).astype(np.float32)

    tensor = torch.from_numpy(processed).unsqueeze(0).to(DEVICE)

    if DEVICE.type == "mps":
        torch.mps.synchronize()

    prep_time = time.perf_counter() - prep_start

    # Model inference
    inference_start = time.perf_counter()

    with torch.inference_mode():
        output = model(tensor)

    if DEVICE.type == "mps":
        torch.mps.synchronize()

    inference_time = time.perf_counter() - inference_start
    total_time = time.perf_counter() - total_start

    preprocessing_times.append(prep_time)
    inference_times.append(inference_time)
    total_times.append(total_time)

print("\n=== REAL AUDIO PIPELINE BENCHMARK ===")
print(f"Device: {DEVICE}")
print(f"Original sample rate: {original_sr} Hz")
print("Target sample rate: 16000 Hz")
print(f"Audio duration: {len(audio) / original_sr:.2f}s")
print(f"Average preprocessing: {np.mean(preprocessing_times)*1000:.2f} ms")
print(f"Average inference: {np.mean(inference_times)*1000:.2f} ms")
print(f"Average total: {np.mean(total_times)*1000:.2f} ms")
print(f"Real-time factor: {3 / np.mean(total_times):.2f}x")

