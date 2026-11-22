

import torch
import coremltools as ct
import numpy as np
from pathlib import Path

traced_path = Path("analysis_reports/coreml/wavlm_traced.pt")
coreml_path = Path("analysis_reports/coreml/U_TALK_WavLM.mlpackage")

print("Loading traced PyTorch model...")
torch_model = torch.jit.load(str(traced_path), map_location="cpu")
torch_model.eval()

print("Loading Core ML model...")
coreml_model = ct.models.MLModel(
    str(coreml_path),
    compute_units=ct.ComputeUnit.CPU_ONLY
)

# Generate identical test input for both models
np.random.seed(42)
audio = np.random.randn(1, 48000).astype(np.float32)

print("Running PyTorch inference...")
with torch.no_grad():
    torch_output = torch_model(torch.from_numpy(audio)).cpu().numpy()

print("Running Core ML inference...")
coreml_output = coreml_model.predict({"audio": audio})

output_name = list(coreml_output.keys())[0]
coreml_scores = np.asarray(coreml_output[output_name])

# Compare outputs
print("\n=== OUTPUT COMPARISON ===")
print("PyTorch shape:", torch_output.shape)
print("Core ML shape:", coreml_scores.shape)

difference = np.abs(torch_output - coreml_scores)

print("Maximum absolute difference:", float(np.max(difference)))
print("Mean absolute difference:", float(np.mean(difference)))

print("\nPyTorch scores:", torch_output)
print("Core ML scores:", coreml_scores)

if np.allclose(torch_output, coreml_scores, rtol=1e-3, atol=1e-4):
    print("\nSUCCESS: Outputs match within tolerance.")
else:
    print("\nWARNING: Outputs differ. Further investigation is needed.")
