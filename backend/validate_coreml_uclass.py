
import torch
import coremltools as ct
import numpy as np
import soundfile as sf
from scipy.signal import resample_poly
from pathlib import Path
from math import gcd
from collections import Counter

AUDIO_PATH = Path.home() / "Desktop/download/M_1064_47y0m_1.wav"
TRACED_PATH = "analysis_reports/coreml/wavlm_traced.pt"
COREML_PATH = "analysis_reports/coreml/U_TALK_WavLM.mlpackage"

WINDOW_SIZE = 48000
HOP_SIZE = 16000

LABELS = [
    "Prolongation",
    "Repetition",
    "Block",
    "Interjection",
    "Fluent"
]

print("Loading UCLASS recording...")
audio, sample_rate = sf.read(str(AUDIO_PATH))

if audio.ndim == 2:
    audio = audio.mean(axis=1)

if sample_rate != 16000:
    divisor = gcd(sample_rate, 16000)
    audio = resample_poly(
        audio,
        16000 // divisor,
        sample_rate // divisor
    )

audio = audio.astype(np.float32)

print("Sample rate:", 16000)
print("Audio duration:", round(len(audio) / 16000, 2), "seconds")

print("\nLoading models...")
torch_model = torch.jit.load(TRACED_PATH, map_location="cpu")
torch_model.eval()

coreml_model = ct.models.MLModel(
    COREML_PATH,
    compute_units=ct.ComputeUnit.ALL
)

torch_predictions = []
coreml_predictions = []
max_differences = []

print("\nComparing windows...")

for start in range(0, len(audio), HOP_SIZE):
    window = audio[start:start + WINDOW_SIZE]

    if len(window) < 16000:
        break

    if len(window) < WINDOW_SIZE:
        window = np.pad(
            window,
            (0, WINDOW_SIZE - len(window))
        )

    window = window.reshape(1, WINDOW_SIZE)

    with torch.no_grad():
        torch_output = torch_model(
            torch.from_numpy(window)
        ).cpu().numpy()

    coreml_result = coreml_model.predict({"audio": window})
    output_name = list(coreml_result.keys())[0]
    coreml_output = np.asarray(coreml_result[output_name])

    difference = np.abs(torch_output - coreml_output)

    torch_class = int(np.argmax(torch_output))
    coreml_class = int(np.argmax(coreml_output))

    torch_predictions.append(torch_class)
    coreml_predictions.append(coreml_class)
    max_differences.append(float(np.max(difference)))

    if len(torch_predictions) % 50 == 0:
        print("Compared", len(torch_predictions), "windows...")

total = len(torch_predictions)
matching = sum(
    t == c
    for t, c in zip(torch_predictions, coreml_predictions)
)

print("\n=== FULL UCLASS CORE ML VALIDATION ===")
print("Total windows:", total)
print("Matching predictions:", matching)
print("Different predictions:", total - matching)
print("Class agreement: {:.2f}%".format(100 * matching / total))
print("Maximum numerical difference:", max(max_differences))
print("Mean maximum difference:", np.mean(max_differences))

print("\nPyTorch prediction counts:")
for index, count in Counter(torch_predictions).items():
    print(LABELS[index] + ":", count)

print("\nCore ML prediction counts:")
for index, count in Counter(coreml_predictions).items():
    print(LABELS[index] + ":", count)

print("\n=== RESULT ===")
if matching == total:
    print("SUCCESS: All predictions match.")
else:
    print("WARNING: Some predictions differ.")
    print("Numerical differences and class changes need review.")
