
import torch
import coremltools as ct
import numpy as np
import soundfile as sf
from scipy.signal import resample_poly
from pathlib import Path
from math import gcd

AUDIO_PATH = Path.home() / "Desktop/download/M_1064_47y0m_1.wav"
TRACED_PATH = "analysis_reports/coreml/wavlm_traced.pt"
COREML_PATH = "analysis_reports/coreml/U_TALK_WavLM.mlpackage"

# Load real recording
print("Loading UCLASS recording...")
audio, sample_rate = sf.read(str(AUDIO_PATH))

# Convert stereo to mono if needed
if audio.ndim == 2:
    audio = audio.mean(axis=1)

# Extract first 3 seconds
audio = audio[:int(sample_rate * 3)]

# Resample to 16 kHz
if sample_rate != 16000:
    divisor = gcd(sample_rate, 16000)
    audio = resample_poly(
        audio,
        16000 // divisor,
        sample_rate // divisor
    )

# Ensure exactly 48,000 samples
audio = audio[:48000]
if len(audio) < 48000:
    audio = np.pad(audio, (0, 48000 - len(audio)))

audio = audio.astype(np.float32).reshape(1, 48000)

print("Input sample rate: 16000 Hz")
print("Input shape:", audio.shape)

# Load both models
print("\nLoading models...")
torch_model = torch.jit.load(TRACED_PATH, map_location="cpu")
torch_model.eval()

coreml_model = ct.models.MLModel(
    COREML_PATH,
    compute_units=ct.ComputeUnit.ALL
)

# Run PyTorch
print("Running PyTorch...")
with torch.no_grad():
    torch_output = torch_model(torch.from_numpy(audio)).cpu().numpy()

# Run Core ML
print("Running Core ML...")
coreml_result = coreml_model.predict({"audio": audio})
output_name = list(coreml_result.keys())[0]
coreml_output = np.asarray(coreml_result[output_name])

# Compare
difference = np.abs(torch_output - coreml_output)

print("\n=== REAL AUDIO VALIDATION ===")
print("PyTorch output:", torch_output)
print("Core ML output:", coreml_output)
print("Maximum difference:", float(np.max(difference)))
print("Mean difference:", float(np.mean(difference)))

torch_class = int(np.argmax(torch_output))
coreml_class = int(np.argmax(coreml_output))

labels = [
    "Prolongation",
    "Repetition",
    "Block",
    "Interjection",
    "Fluent"
]

print("\nPyTorch prediction:", labels[torch_class])
print("Core ML prediction:", labels[coreml_class])

if np.allclose(torch_output, coreml_output, rtol=1e-3, atol=1e-4):
    print("\nSUCCESS: Real-audio outputs match.")
else:
    print("\nWARNING: Real-audio outputs differ.")

if torch_class == coreml_class:
    print("SUCCESS: Both models predict the same class.")
else:
    print("WARNING: Predicted classes differ.")
