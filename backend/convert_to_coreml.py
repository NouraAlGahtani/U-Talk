
import torch
import coremltools as ct
from pathlib import Path

source = Path("analysis_reports/coreml/wavlm_traced.pt")
destination = Path("analysis_reports/coreml/U_TALK_WavLM.mlpackage")

print("PyTorch:", torch.__version__)
print("Core ML Tools:", ct.__version__)
print("Loading traced model...")

model = torch.jit.load(str(source), map_location="cpu")
model.eval()

print("Starting Core ML conversion...")
print("Input: 1 x 48000 float32 (3 seconds at 16 kHz)")

mlmodel = ct.convert(
    model,
    inputs=[
        ct.TensorType(
            name="audio",
            shape=(1, 48000),
            dtype=float
        )
    ],
    convert_to="mlprogram",
    minimum_deployment_target=ct.target.iOS16,
    compute_precision=ct.precision.FLOAT32,
    debug=True
)

print("Conversion successful!")
mlmodel.save(str(destination))

print("Saved:", destination)
print("Model input:", mlmodel.input_description)
print("Model output:", mlmodel.output_description)

