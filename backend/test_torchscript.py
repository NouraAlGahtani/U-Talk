
import torch
from pathlib import Path

from evaluate_sep28k_reviewed import StutteringClassifier, CHECKPOINT

print("Loading model...")

model = StutteringClassifier()

checkpoint = torch.load(
    CHECKPOINT,
    map_location="cpu",
    weights_only=False
)

model.load_state_dict(checkpoint["model_state_dict"], strict=True)
model.eval()

example = torch.randn(1, 48000)

print("Testing TorchScript tracing...")

with torch.inference_mode():
    eager_output = model(example)

    traced = torch.jit.trace(
        model,
        example,
        check_trace=True
    )

    traced_output = traced(example)

torch.testing.assert_close(
    eager_output,
    traced_output,
    rtol=1e-4,
    atol=1e-5
)

output_path = Path("analysis_reports/coreml/wavlm_traced.pt")
traced.save(str(output_path))

print("SUCCESS: TorchScript tracing worked!")
print("Output shape:", tuple(traced_output.shape))
print("Saved:", output_path)

